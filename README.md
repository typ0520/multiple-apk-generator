## multiple-apk-generator简介
---- 
* 解决android apk的批量打包,支持渠道号替换(字符串替换)、资源替换、指定文件修改、修改包名
* 轻量级: 使用shell脚本编写，方便开发者修改实现逻辑
* 基于gradle打包apk

欢迎大家参与进来完善这个项目，如果你在使用过程中碰到问题或者有改进建议可以给我发邮件
php12345@163.com
 

## 使用说明
----
注: 需要依赖shell环境，mac和linux可以直接使用；如果是windows需要装模拟linux环境的shell工具(xshell、cygwin)

``` 
1. 把multiple-apk-generator.sh复制到gradle的项目根目录
2. 在项目根目录下新建zz-targets目录，保存apk的配置信息
3. zz-targets中新建代表一个打包任务的文件夹,名字是(对应的module的名字 + 下划线 + xxxx)
4. 在第一步新建的目录下面创建makefile文件，使用规定的描述语言(参考下面一节)描述输出apk之前做的一些资源替换操作

``` 

## 描述语言说明
----
目前支持的插件有6种

1. 修改目标app的包名
2. 修改目标app的名字
3. 递归替换某个文件夹的所有文件中的某个字符串
4. 替换某个文件中的某个字符串
5. 替换某个文件
6. 替换某个文件中的指定行内容

>以下是samples项目其中一个makefile内容(详情可以参考samples项目)

``` 
#修改目标包名
package com.example.samples2

#修改app的名字
app_name 测试项目

#复制文件(如果对应的文件存在就覆盖掉)
copy_file app_icon.png src/main/res/drawable-hdpi/ic_launcher.png

#把src/main/目录下所有文件中包含的字符串testString，替换为testString2
match_all src/main/ testString pretestStringsub

#把config.java的中的字符串github修改为aagithubbb
match_file src/main/java/com/example/samples/Config.java github aagithubbb

#把src/main/assets/test.txt文件的第5行内容替换成replace-line5ffgdg
replace_line src/main/assets/test.txt 5 replace-line5ffgdg


``` 
>注意事项

1. 最终输出的apk，在zz-targets/out目录下
2. 在描述文件中以#开头的是注释，会被忽略掉
3. 描述语言以行为单位 ，按空格分隔，第一个单词为动作，后面的依次为${1}  ${2}  ${3}  ......
4. target目录名字以module的名字加下划线开头，再加上数字或字母(例如: app_1)
5. 描述文件(makefile)参数中不能出现空格
