#注意: 参数中不要出现空格
#支持的内置常量:
#   ${src}可以代替    src/main/java
#   ${res}可以代替    src/main/res
#   ${assets}可以代替 src/main/assets

#修改目标包名
package com.example.samples2

#修改app的名字(把AndroidManifest.xml中的字符串@string/app_name，修改成参数1指定的名字)
app_name 测试项目

#复制文件(如果对应的文件存在就覆盖掉)
copy_file app_icon.png ${res}/drawable-hdpi/ic_launcher.png

#把src/main/目录下所有文件中包含的字符串testString，替换为testString2
match_all ${src} testString pretestStringsub

#修改服务器地址
match_all ${src} www.baidu.com www.google.com

#把config.java的中的字符串github修改为aagithubbb
match_file ${src}/com/example/samples/Config.java github aagithubbb

#把src/main/assets/test.txt文件的第5行内容替换成replace-line5ffgdg(**参数3的内容不要出现空格)
#                                       参数3
replace_line ${assets} 5 replace-line5ffgdg



