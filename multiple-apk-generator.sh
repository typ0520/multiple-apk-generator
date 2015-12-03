#!/bin/bash

#
# Author :  Ya-Peng-Tong
# Version:  0.2-beta-2
# Github :  https://github.com/typ0520/multiple-apk-generator
#
# 使用说明：
# 1、在项目根目录下新建zz-targets目录，保存target相关配置
# 2、zz-targets中新建target文件夹,文件夹名字是(对应的module的名字 + 下划线 + xxxx)
# 3、在第一步新建的target目录下面创建makefile文件，使用规定的描述语言描述输出apk之前做的一些资源替换操作
# 4、在项目根目录执行此脚本  cd ${project_root};  ./multiple-apk-generator.sh
#
# 描述语言说明:
# 1、配置目标生成项目的包名为${1}
#   packname com.example.samples2
#
# 2、修改app的名字
#   app_name 测试项目
#
# 3、把src/main/目录下所有文件中包含的字符串testString，替换为testString2(使用这个可以完成渠道号替换或者服务器地址替换)
#   match_all src/main/ testString pretestStringsub
#
# 4、使用${2}匹配并替换${0}文件中的${1}
#   match-file src/main/AndroidManifest.xml com.example.samples com.example.samples2
#
# 5、使用${1}的对应文件替换${2}对应的文件
#   copy_file app_icon.png src/main/res/drawable-hdpi/ic_launcher.png
#
# 6、#把${2}文件中的第${1}行的内容替换成${2}对应内容(参数3的内容如果包含空格使用${space}代替)
#   replace_line ${res}/values/strings.xml 6 <string${space}name="prompt_email">multiple-apk-generator</string>
#
# 描述语言内置常量:
#   ${src}      代替 src/main/java
#   ${res}      代替 src/main/res
#   ${assets}   代替 src/main/assets
#   ${space}    代替 空格
#
# 注: 最终输出的apk，在zz-targets/out目录下
# 注: 在描述文件中以#开头的是注释，会被忽略掉
# 注: 描述语言以行为单位 ，按空格分隔，第一个单词为动作，后面的依次为${1}  ${2}  ${3}  ......
# 注: target目录名字以module的名字加下划线开头，再加上数字或字母(例如: app_1)
# 注: 描述文件(makefile)参数中如果需要使用空格，用${space}代替
#

#
# Change logs:
# >> 0.1-beta-1
# 1、修复在某些情况下包名无法修改的情况
#
# >> 0.1-beta-2
# 1、修改快照保存路径到项目根目录下名字为.zz-project-snapshot的目录，方便比对生成的项目代码是否正确
# 2、targets读取路径改成从快照目录下读取
#
# >> 0.2-beta-1
# 1、zz-targets目录下可以添加ignore目录，把暂时不需要打包的target资源移动到这个目录
# 2、添加内置变量 ${src} ${res} ${assets}
# 3、添加对参数中需要加空格的处理逻辑,使用${space}代替空格
#
# >> 0.2-beta-2
# 1、修改更换app名字的逻辑，以前需要app的名字配置为@string/app_name，现在没有这个限制了
# 2、暂时不需要打包的target，可以把名字放在zz-targets下面的.zzignore文件中
# 3、解决makefile未配置修改包名时，也会执行package动作的问题
#

IFS=$'\n'

#是否是调试状态
DEBUG=0

#shell执行目录
PWD=$(pwd)

#工程目录
PROJECT_PATH=$(pwd)

#获取gradle项目根目录名字
PROJECT_NAME=${PROJECT_PATH##*/}

#目标目录名字
TARGETS_DIR_NAME="zz-targets"

#描述文件名
MK_FILE_NAME="makefile"

#临时文件目录
TEMP_PATH="${HOME}/.${TARGETS_DIR_NAME}-work/${PROJECT_NAME}"

#目录apk输出路径
TARGET_APK_PATH="${PROJECT_PATH}/${TARGETS_DIR_NAME}/out"

#工程快照名字
SNAPSHOT_NAME=".zz-project-snapshot"

#工程快照
SNAPSHOT_PATH="${PROJECT_PATH}/${SNAPSHOT_NAME}"

#target保存路径
TARGETS_PATH="${SNAPSHOT_PATH}/${TARGETS_DIR_NAME}"

#===util function start===
#打印调试日志
function dlog() {
    if [ ${DEBUG} != 0 ];then
         echo $1
    fi
}

#打印日志
function log() {
    echo $1
}

#打印错误信息
function elog() {
    echo "--warn, ${1}"
}

#是否是gradle根项目
#args  : ${1}: 被检测目录
#return: 1: yes 0: no
function is_root_gradle_project() {
    dlog "is_root_gradle_project |${1}|"
    if [ -f "${1}/build.gradle" ] && [ -f "${1}/settings.gradle" ];then
        return 1
    fi
    return 0
}

#是否是gradle项目
#args  : ${1}: 被检测目录
#return: 1: yes 0: no
function is_gradle_project() {
   if [ -f "${1}/build.gradle" ];then
        return 1
   fi
   return 0
}

#是否是app的gradle项目
#args  : ${1}: 被检测目录
#return: 1: yes 0: no
function is_app_gradle_project() {
   if [ -f "${1}/build.gradle" ];
   then
        cat "${1}/build.gradle" | grep 'com.android.application' > /dev/null 2>&1
        if [ $? == 0 ];then
           return 1
        fi
   fi
   return 0
}
#=util function end=

#===plugin function start ===

#替换多个文件中的内容 ${1}: 目标module ${2}: 从这个路径下开始搜索 ${3}: 被替换的内容 ${4}: 目标内容
function match_all() {
    dlog "match_all target: ${1},search_root: ${2},src_str: ${3},dest_str: ${4}"
    search_path="${SNAPSHOT_PATH}/${1}/${2}"
    dlog "search_path: ${search_path}"

    find ${search_path} | while read line
    do
        #忽略掉文件夹
        if [ -f ${line} ];then
            cat $line | grep $3
            if [ $? == 0 ];then
                  dlog "match_all : ${line}"
            fi
            sed -i.zztmp "s/${3}/${4}/g" ${line}
            rm "${line}.zztmp"  > /dev/null 2>&1
        fi
    done
}

#复制文件 ${1}: 目标module  ${2}: 应用的名字
function app_name() {
    dlog "app_name |${1},${2}"
    log "${1} rename app_name to ${2}"

    file_path="${SNAPSHOT_PATH}/${1}/src/main/AndroidManifest.xml"
    manifest_doc=$(cat ${file_path} | tr -d '\n')
    application_node=$(echo ${manifest_doc} | grep -o -E '(<application[^>]{1,}>)')
    application_node_target=$(echo ${application_node} | sed -E "s/(android:label=\"[^\"]{1,}\")/android:label=\"${2}\"/g")
    manifest_doc=${manifest_doc/${application_node}/${application_node_target}}
    echo ${manifest_doc} > ${file_path}
}

#复制文件 ${1}: 目标module  ${2}: 源文件相对路径 ${3}: 目标文件相对路径
function copy_file() {
    dlog "copy_file |${1},${2},${3}|"

    src_file_path="${TARGETS_PATH}/${1}/${2}"
    target_file_path="${SNAPSHOT_PATH}/${1}/${3}"

    dlog "copy_file src_file_path: ${src_file_path}"
    if [ ! -f ${src_file_path} ];then
        elog "file not found!!  ${src_file_path}"
        exit 1
    fi
    dlog "copy_file target_file_path: ${target_file_path}"
    cp ${src_file_path} ${target_file_path}
}

#替换指定行内容
function replace_line() {
    target=${1}
    file_path="${SNAPSHOT_PATH}/${1}/${2}"
    line_num=${3}
    target_string=${4}
    dlog "replace_line |${1},${2},${3},${4}|"
    dlog "replace_line file_path: ${file_path}"

    temp_file="${file_path}.zztmp"
    dlog "replace_line head -n $((${line_num} - 1))"
    head -n $((${line_num} - 1)) ${file_path} > ${temp_file}

    total_line_num=$(cat -n ${file_path} | tail -n1 | awk '{print $1}')
    remain_line_num=$((${total_line_num} - ${line_num}))

    dlog "replace_line total_line_num: ${total_line_num} ,remain_line_num: ${remain_line_num}"
    #替换转义字符

    echo ${target_string} | sed -e 's/${space}/ /g' >> ${temp_file}
    tail -n ${remain_line_num} ${file_path} >> ${temp_file}

    cat ${temp_file} > ${file_path}

    rm "${temp_file}" > /dev/null 2>&1
}

#替换单体文件中的内容 ${1}: 目标module  ${2}: 目标文件相对路径 ${3}: 被替换的内容 ${4}: 目标内容
function match_file() {
    target=${1}
    target_file=${2}

    src_str=${3}
    dest_str=${4}
    dlog "match_file target: ${1},target_file: ${target_file},src_str: ${src_str},dest_str: ${dest_str}"

    file_path="${SNAPSHOT_PATH}/${target}/${target_file}"
    sed -i.zztmp "s/${src_str}/${dest_str}/g" ${file_path}
    rm "${file_path}.zztmp" > /dev/null 2>&1
}

#替换项目包名
function package() {
    target=${1}
    src_project=${2}
    package_name=${3}

    #目标工程路径
    target_dir="${SNAPSHOT_PATH}/${target}"
    manifest="src/main/AndroidManifest.xml"

    cat ${target_dir}/${manifest} | grep -o -E '(package\s{0,}=\s{0,}"[.a-zA-Z]{1,}")' > /dev/null 2>&1
    if [ $? != 0 ];then
        elog "resolve xml error, when get old package name. check your manifest file: ${src_project}/${manifest}"
        exit 1
    fi
    old_package_string=$(cat ${target_dir}/${manifest} | grep -o -E '(package\s{0,}=\s{0,}"[.a-zA-Z]{1,}")')

    old_package_name=$(cat ${target_dir}/${manifest} | grep -o -E '(package\s{0,}=\s{0,}"[.a-zA-Z]{1,}")' | sed 's/[[:space:]]//g')

    #删除package="及其左边的字符
    old_package_name=${old_package_name#*package=\"}
    #删除右边双引号
    old_package_name=${old_package_name/\"}

    log "rename $target package ${old_package_name} to $package_name"

    match_file ${target} "build.gradle" ${old_package_name} ${package_name}
    match_file ${target} ${manifest} ${old_package_string} "package=\"${package_name}\""
    match_all ${target} "src/main/java" "${old_package_name}.R" "${package_name}.R"

    search_path="${SNAPSHOT_PATH}/${1}/src/main/java"
    dlog "search_path: ${search_path}"

    #为所有的java文件添加对R文件的引用
    find ${search_path} -name '*.java' | while read line
    do
        src_str=$(cat ${line} | grep 'package')
        dest_str="${src_str}import ${package_name}.R;"

        sed -i.zztmp "s/${src_str}/${dest_str}/g" ${line} > /dev/null 2>&1
        rm "${line}.zztmp" > /dev/null 2>&1
    done
}

#===plugin function end ===

#预处理makefile
function pretreatment_makefile() {
    makefile=${1}
    #替换环境变量
    env_var_key_array=("\${src}" "\${res}" "\${assets}")
    env_var_value_array=("src\/main\/java" "src\/main\/res" "src\/main\/assets")
    dlog "pretreatment_makefile: ${1}"

    index=0
    for key in ${env_var_key_array[@]}
    do
        val=${env_var_value_array[index]}
        dlog "key: ${key},val: ${val}"

        sed -i.zztmp "s/${key}/${val}/g" ${makefile} #> /dev/null 2>&1
        rm "${makefile}.zztmp" #> /dev/null 2>&1
        index=$((index + 1))
    done
}

#生成target  ${1}: 目标名字  ${2}: 源项目
function generate_target() {
    dlog "generate_target |${1},${2}|"
    target=${1}
    src_project=${2}
    #dlog "target: $target , src_project: $src_project"
    #复制一个以target命名的新项目，以src_project为蓝本
    dlog "cp  ${SNAPSHOT_PATH}/${src_project}   to  ${SNAPSHOT_PATH}/${target}"
    cp -r "${SNAPSHOT_PATH}/${src_project}" "${SNAPSHOT_PATH}/${target}"
    #把新的工程配置添加到settings.gradle
    echo "include ':${target}'" >> "${SNAPSHOT_PATH}/settings.gradle"

    #判断makefile文件是否存在
    config_file="${TARGETS_PATH}/${target}/${MK_FILE_NAME}"
    if [ ! -f $config_file ];then
        elog "makefile not found: ${config_file}"
        exit 1;
    fi

    #预处理makefile
    pretreatment_makefile ${config_file}

    #解析并执行描述文件
    cat $config_file | while read line
    do
        line=$(echo $line)
        if [ "$line" != "" ] && [ "${line:0:1}" != '#' ];then
            action=$(echo $line | awk '{print $1}')
            if [ "$action" != "package" ];then
                #调用插件对应的函数并传参
                dlog "《《《 ${line/$action/$target}"
                "$action" ${target} $(echo $line | awk '{print $2}') $(echo $line | awk '{print $3}') $(echo $line | awk '{print $4}') $(echo $line | awk '{print $5}')
            else
                #调用插件对应的函数并传参
                dlog "《《《 ${line/$action/$target}"
                "$action" ${target} ${src_project} $(echo $line | awk '{print $2}') $(echo $line | awk '{print $3}') $(echo $line | awk '{print $4}') $(echo $line | awk '{print $5}')
            fi
        fi
    done
}

#初始化上下文
function init_context() {
    #删除上次的快照
    rm -rf ${SNAPSHOT_PATH}
    log "Generating project snapshot .... "
    #清理项目临时文件
    #gradle clean > /dev/null 2>&1

    #如果临时文件路径不存在就创建
    if [ ! -d ${TEMP_PATH} ];then
        mkdir -p ${TEMP_PATH}
    fi

    #生成项目快照，保存在工作目录
    cp -r ${PROJECT_PATH} ${TEMP_PATH}
    mv ${TEMP_PATH}/${PROJECT_NAME} ${SNAPSHOT_PATH}

    #把工作目录加入到.gitignore
    if [ -d "${PROJECT_PATH}/.git" ];then
        if [ ! -f "${PROJECT_PATH}/.gitignore" ];then
            echo ${SNAPSHOT_NAME} > "${PROJECT_PATH}/.gitignore"
        else
             cat ${PROJECT_PATH}/.gitignore | grep "${SNAPSHOT_NAME}" > /dev/null 2>&1
             if [ $? == 1 ];then
                echo ${SNAPSHOT_NAME} >> "${PROJECT_PATH}/.gitignore"
             fi
        fi
    fi
}

function generate_targets() {
    #判断脚本执行的路径是否是gradle工程的根路径
    is_root_gradle_project ${PROJECT_PATH}

    if [ $? == 0 ];then
        elog "execution path is not root gradle project(build.gradle or settings.gradle not found)"
        exit 1
    fi

    #需要生成的目标数组
    TARGET_ARRAY=()
    index=1;
    #扫描需要生成的target
    for file in $(ls "${PROJECT_PATH}/${TARGETS_DIR_NAME}")
      do
       if [ -d "${PROJECT_PATH}/${TARGETS_DIR_NAME}/$file" ]  && [ $file != 'out' ] && [ $file != 'ignore' ] ;then
            cat "${PROJECT_PATH}/${TARGETS_DIR_NAME}/.zzignore"  2> /dev/null  | grep "${file}" > /dev/null
            skip=$?

            if [ ! -f ${zzignore_file} ] || [ ${skip} == 1 ];then
                #判断是否是有效的target名字(以存在的app项目的名字加上下划线开头)
                is_app_gradle_project ${file%_*}

                if [[ $? == 1 ]];then
                    #检查makefile是否存在
                    if [ ! -f "${PROJECT_PATH}/${TARGETS_DIR_NAME}/${file}/${MK_FILE_NAME}" ];then
                         elog "makefile not found: ${PROJECT_PATH}/${TARGETS_DIR_NAME}/${file}/${MK_FILE_NAME}"
                         exit 1;
                    fi

                    TARGET_ARRAY[$index]=$file
                    index=$((index + 1))
                else
                    elog "invalid target: '$file', '${PROJECT_PATH}/${file%_*}' is not a valid gradle android application project"
                    exit 1
                fi
            fi
       fi
    done

    #初始化环境
    init_context

    #生成各个目标的源代码
    for target in ${TARGET_ARRAY[@]}
    do
        generate_target ${target} ${target%_*}
    done

    rm -rf ${TARGET_APK_PATH}

    report_file="${TEMP_PATH}/report_file.txt"
    rm -rf ${report_file};touch ${report_file}

    log 'Generating apk ...'
    #打包apk
    for target in ${TARGET_ARRAY[@]}
    do
        cd ${SNAPSHOT_PATH}/${target}
        gradle clean build
        if [ $? == 0 ];then
            echo "Build success  target: ${target}" >> ${report_file}
            if [ ! -d ${TARGET_APK_PATH} ];then
                mkdir -p ${TARGET_APK_PATH}
            fi

            dlog "Copying apk with gradle ..."
            ls ${SNAPSHOT_PATH}/${target}/build/outputs/apk | while read line
            do
                dlog ${line}
                cp "${SNAPSHOT_PATH}/${target}/build/outputs/apk/${line}" ${TARGET_APK_PATH}/${line}
            done
        else
            echo "Build fail     target: ${target}" >> ${report_file}
        fi
    done
    cd ${PWD}

    #输出报告
    echo ''
    log '==== Report ===='
    if [ -d ${TARGET_APK_PATH} ];then
        log 'All generated apk: '
        ls ${TARGET_APK_PATH} | while read line
        do
             log "   ${line}"
        done
        echo ''
    fi
    cat ${report_file}
}

#根据zz-targets目录配置的信息，生成目标apk
generate_targets