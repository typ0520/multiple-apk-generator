#注意: 参数中不要出现空格,如果某个参数需要使用空格使用${space}代替

#支持的内置常量:
#   ${src}      代替 src/main/java
#   ${res}      代替 src/main/res
#   ${assets}   代替 src/main/assets
#   ${space}    代替 空格

#修改目标包名
package com.example.samples2

#修改app的名字(把AndroidManifest.xml中的字符串@string/app_name，修改成参数1指定的名字)
app_name 测试项目

#复制文件(如果对应的文件存在就覆盖掉)
copy_file app_icon.png ${res}/drawable-hdpi/ic_launcher.png

#把src/main/目录下所有文件中包含的字符串testString，替换为testString2(可用于替换渠道号、服务器地址)
match_all ${src} testString pretestStringsub

#把config.java的中的字符串github修改为aagithubbb
match_file ${src}/com/example/samples/Config.java github multiple-apk-generator

#把src/main/assets/test.txt文件的第5行内容替换成replace-line5ffgdg
replace_line ${assets}/test.txt 5 replace-line5multiple-apk-generator

#参数3的内容如果包含空格使用${space}代替
replace_line ${res}/values/strings.xml 6 <string${space}name="prompt_email">multiple-apk-generator</string>


