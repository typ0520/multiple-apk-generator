#!/bin/bash

#
# Author :  Ya-Peng-Tong
# Version:  v1.0
# Github :  https://github.com/typ0520/multiple-apk-generator
#
# 使用说明：
# 1、zz-targets中新建一个保存   输出目标相关配置信息,目标名字(文件夹)是对应的android app gradle
# 2、在第一步新建的目录下面创建dgconfig.txt，使用规定的描述语言描述输出apk之前做的一些资源替换操作
# 3、执行此脚本，命令行下cd到项目根目录下(OnlineEnglishEducate)  执行./dynamic-generate.sh
#
# 描述语言说明:
# 1、配置目标生成项目的包名为${1}
#   packname com.example.comprehension
#
# 2、使用${2}匹配并替换${0}文件中的${1}
#   match-file src/main/AndroidManifest.xml com.example.comprehension com.example.colze
#
# 3、使用${2}匹配并替换${0}为根目录下的所有文件中的${1}
#   match-all src/main/java/ com.example.comprehension.R com.example.colze.R
#
# 4、使用${1}的对应文件替换${2}对应的文件
#   copy_file ic_launcher.png src/main/res/drawable-hdpi/ic_launcher.png
#
# 5、#把${2}文件中的第${1}行的内容替换成${2}对应内容
#   replace-line 4 src/main/res/values/strings.xml <string name="app_name">完形填空</string>
#
#
# 注: 最终输出的apk，
# 注: 在描述文件中以#开头的是注释，会被忽略掉
# 注: 描述语言以行为单位 ，按空格分隔，第一个单词为动作，后面的依次为${1}  ${2}  ${3}  ......
# 注: 模版文件目录已colze_或者comprehension_开头
# 注: 描述文件(metadatd.dsl)参数中不能出现空格
#

#
# Next version expect
# 1、把项目快照存放在项目结构下(方便查看生成的代码是否正确)   [ok]
# 2、把生成的所有apk全部copy到zz-targets/out目录下
# 3、生成结果报告
# 4、把target配置的方式由目录改成文件(接入方便)
#

IFS=$'\n'

#是否是调试状态
DEBUG=1

#shell执行目录
PWD=$(pwd)

#工程目录
PROJECT_PATH=$(pwd)

#获取gradle项目根目录名字
PROJECT_NAME=${PROJECT_PATH##*/}

#目标目录名字
TARGETS_DIR_NAME="zz-targets"

#工作目录名字
WORKSPACE_NAME=".${TARGETS_DIR_NAME}-work"

#描述文件名
MK_FILE_NAME="makefile"

#工作目录
WORK_PATH="${PROJECT_PATH}/${WORKSPACE_NAME}"

#临时文件目录
TEMP_PATH="${HOME}/${WORKSPACE_NAME}/${PROJECT_NAME}"

#目标路径
TARGETS_PATH="${PROJECT_PATH}/${TARGETS_DIR_NAME}"

#目录apk输出路径
TARGET_APK_PATH="${TARGETS_PATH}/out"

#工程快照
SNAPSHOT_PATH="${WORK_PATH}/${PROJECT_NAME}-snapshot"

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
            sed -i.dgtmp "s/${3}/${4}/g" ${line}
            rm "${line}.dgtmp"  > /dev/null 2>&1
        fi
    done
}

#复制文件 ${1}: 目标module  ${2}: 应用的名字
function app_name() {
    dlog "app_name |${1},${2}"
    file_path="${SNAPSHOT_PATH}/${1}/src/main/res/values/strings.xml"
    manifest="src/main/AndroidManifest.xml"
    match_file ${1} ${manifest} "\@string\/app_name" "${2}"
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
    dlog "replace_line |${1},${2},${3},${4}|"

    file_path="${SNAPSHOT_PATH}/${1}/${2}"
    dlog "replace_line file_path: ${file_path}"
    sed -i.dgtmp "${3}s/.*/${4}/" ${file_path}
    rm "${file_path}.dgtmp" > /dev/null 2>&1
}

#替换单体文件中的内容 ${1}: 目标module  ${2}: 目标文件相对路径 ${3}: 被替换的内容 ${4}: 目标内容
function match_file() {
    target=${1}
    target_file=${2}

    src_str=${3}
    dest_str=${4}
    dlog "match_file target: ${1},target_file: ${target_file},src_str: ${src_str},dest_str: ${dest_str}"

    file_path="${SNAPSHOT_PATH}/${target}/${target_file}"
    sed -i.dgtmp "s/${src_str}/${dest_str}/g" ${file_path}
    rm "${file_path}.dgtmp" > /dev/null 2>&1
}

#替换项目包名
function package() {
    target=${1}
    src_project=${2}
    package_name=${3}

    #目标工程路径
    target_dir="${SNAPSHOT_PATH}/${target}"
    manifest="src/main/AndroidManifest.xml"

    old_package_name=$(cat ${target_dir}/${manifest} | grep "package=\"")
    old_package_name=${old_package_name/package=\"/}
    old_package_name=${old_package_name/\"}
    old_package_name=$(echo ${old_package_name} | sed -e 's/\(^ *\)//' -e 's/\( *$\)//')

    log "rename $target package ${old_package_name} to $package_name"

    match_file ${target} "build.gradle" ${old_package_name} ${package_name}
    match_file ${target} ${manifest} "package=\"${old_package_name}\"" "package=\"${package_name}\""
    match_all ${target} "src/main/java" "${old_package_name}.R" "${package_name}.R"

    search_path="${SNAPSHOT_PATH}/${1}/src/main/java"
    dlog "search_path: ${search_path}"

    #为所有的
    find ${search_path} -name '*.java' | while read line
    do
        src_str=$(cat ${line} | grep 'package')
        dest_str="${src_str}import ${package_name}.R;"

        sed -i.dgtmp "s/${src_str}/${dest_str}/g" ${line} > /dev/null 2>&1
        rm "${line}.dgtmp" > /dev/null 2>&1
    done
}

#===plugin function end ===

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

    #解析并执行描述文件
    #获取配置的包名
    package_name=$(cat "$config_file"| grep 'package' | awk '{print $2}')
    package_name=${package_name:="com.example.${target}"}
    dlog "==package: ${package_name}"
    package $target $src_project $package_name

    cat $config_file | while read line
    do
        line=$(echo $line)
        if [ "$line" != "" ] && [ "${line:0:1}" != '#' ];then
            action=$(echo $line | awk '{print $1}')
            if [ "$action" != "package" ];then
                #调用动作对应的c函数并传参
                dlog "《《《 ${line/$action/$target}"
                "$action" ${target} $(echo $line | awk '{print $2}') $(echo $line | awk '{print $3}') $(echo $line | awk '{print $4}') $(echo $line | awk '{print $5}')
            fi
        fi
    done
}

#初始化上下文
function init_context() {
    rm -rf ${WORK_PATH}
    log "Generating project snapshot .... "
    #清理项目临时文件
    gradle clean > /dev/null 2>&1

    #如果临时文件路径不存在就创建
    if [ ! -d ${TEMP_PATH} ];then
        mkdir -p ${TEMP_PATH}
    fi

    #生成项目快照，保存在工作目录
    cp -r ${PROJECT_PATH} ${TEMP_PATH}
    mkdir -p ${WORK_PATH}
    mv ${TEMP_PATH}/${PROJECT_NAME} ${SNAPSHOT_PATH}

    #把工作目录加入到.gitignore
    if [ -d "${PROJECT_PATH}/.git" ];then
        if [ ! -f "${PROJECT_PATH}/.gitignore" ];then
            echo ${WORKSPACE_NAME} > "${PROJECT_PATH}/.gitignore"
        else
             cat ${PROJECT_PATH}/.gitignore | grep "${WORKSPACE_NAME}" > /dev/null 2>&1
             if [ $? == 1 ];then
                echo ${WORKSPACE_NAME} >> "${PROJECT_PATH}/.gitignore"
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
    for file in $(ls ${TARGETS_PATH})
      do
       if [ -d "$TARGETS_PATH/$file" ]  && [ $file != 'out' ] ;then
            #判断是否是有效的target名字(以存在的app项目的名字加上下划线开头)
            is_app_gradle_project ${file%_*}

            if [[ $? == 1 ]];then
                #dlog "$METADATD_DIR/$file"
                #检查makefile是否存在
                if [ ! -f "${TARGETS_PATH}/${file}/${MK_FILE_NAME}" ];then
                     elog "makefile not found: ${TARGETS_PATH}/${file}/${MK_FILE_NAME}"
                     exit 1;
                fi

                TARGET_ARRAY[$index]=$file
                index=$((index + 1))
            else
                elog "invalid target: '$file', '${PROJECT_PATH}/${file%_*}' is not a valid gradle android application project"
                exit 1
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

    #打包apk
    for target in ${TARGET_ARRAY[@]}
    do
        cd ${SNAPSHOT_PATH}/${target}
        gradle clean build
        if [ $? == 0 ];then
            if [ ! -d ${TARGET_APK_PATH} ];then
                mkdir -p ${TARGET_APK_PATH}
            fi

            ls ${SNAPSHOT_PATH}/${target}/build/outputs/apk | while read line
            do
                log ${line}
                cp "${SNAPSHOT_PATH}/${target}/build/outputs/apk/${line}" ${TARGET_APK_PATH}/${line}
            done
        else
            log "《《《 genarate apk fail !!!!"
        fi
    done
    cd ${PWD}
}

#根据zz-targets目录配置的信息，生成目标apk
generate_targets