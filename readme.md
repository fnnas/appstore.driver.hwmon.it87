# ite-it87 — IT87/IT86 硬件监控传感器驱动

适用于 [飞牛NAS (fnOS)](https://www.fnnas.com) 的 IT87/IT86 系列传感器芯片树外内核驱动包。

## 简介

本项目将上游 [IT87 驱动](https://github.com/fnnas/it87) 编译为预构建内核模块 (`.ko`)，并打包为飞牛NAS应用商店可安装的驱动包，提供温度、电压、风扇转速等硬件传感器监控功能。

该驱动由飞牛社区用户提供并维护。如遇问题，请直接向飞牛社区或本项目仓库issue反馈，反馈时请提供导出的日志。

## 支持的内核版本

默认构建并打包以下内核的预构建模块：

- `6.18.18.c788-trim`
- `6.18.18.c877-trim`
- `6.18.18.c938-trim`
- `6.18.18.c952-trim`
- `6.18.18.c1032-trim`
- `6.18.18.c1078-trim`
- `6.18.18.c1126-trim`
- `6.18.18.c1168-trim`
- `6.18.18.c1179-trim`

## 支持的架构

- x86_64

## 安装

通过应用商店直接安装，需要 **root 权限**。

## 构建与发布

GitHub Actions 使用 `Test Release` 工作流完成构建、打包和发布检查，两组内核矩阵共用 `kernel-build.yml` 编译流程。`build` 默认构建带 `.c` 编号的内核；不带 `.c` 编号的旧内核仅保留用于调试，由 `build_old_kernels` 单独控制，默认关闭。启用后，会额外构建并打包全部 6 个旧内核模块变体，旧内核不列入对外支持列表。

打包阶段直接在工作流中的 `package/manifest` 上替换构建时占位值，再把生成的 `app.tgz` 放入 `package/` 目录并打包最终应用包。

已有暂存包可通过 `bash scripts/validate-package.sh <staged-package-dir>` 校验；如果构建时启用了旧内核，使用 `BUILD_OLD_KERNELS=true bash scripts/validate-package.sh <staged-package-dir>`，同时检查旧内核产物。

发布由手动触发参数 `make_release` 控制，默认不会创建 GitHub Release。只有显式打开 `make_release` 时，工作流才会创建 Release 并上传产物。

## 国际化

应用描述、更新说明、安装向导和运行提示支持中文、英文与日文，文案统一维护在 `package/i18n/zh`、`package/i18n/en` 和 `package/i18n/ja-JP`。运行脚本优先使用飞牛系统提供的 `TRIM_SYS_LANGUAGE`，未设置时依次读取 `LC_ALL`、`LC_MESSAGES`、`LANG`；中文地区代码使用中文，`ja`、`ja-JP`、`ja_JP.UTF-8` 等日语代码使用日文，其他语言或缺失译文回退到英文。

应用描述和更新说明中的驱动提交标识由 CI 与 `package/manifest` 一起替换，处理后的语言文件也会随应用 payload 分发供运行脚本读取。新增内核支持时，需要同步更新三份语言资源中的支持列表。可在仓库根目录运行 `bash scripts/validate-workflows-and-scripts.sh` 检查脚本，以及三种语言的键、参数数量、引用和内核支持列表是否一致。

## 故障诊断
可以通过筛选it87相关日志观察  
```shell
root@MEmini:~# dmesg |grep it87
[2618117.649368] it87: it87 driver version v1.0-208-gd17546b.20260305
[2618117.649601] it87: Found IT8613E chip at 0xa30, revision 12
[2618117.649667] it87: Beeping is supported
```

## 使用
首先找到哪个hwmon是由it87驱动提供的  
```shell
for d in /sys/class/hwmon/hwmon*; do
    echo -n "$d: "
    cat $d/name
done
```

如下例，hwmon9为it87提供  
```text
/sys/class/hwmon/hwmon0: acpitz
/sys/class/hwmon/hwmon1: nvme
/sys/class/hwmon/hwmon2: nvme
/sys/class/hwmon/hwmon3: nvme
/sys/class/hwmon/hwmon4: nvme
/sys/class/hwmon/hwmon5: nvme
/sys/class/hwmon/hwmon6: nvme
/sys/class/hwmon/hwmon7: iwlwifi_1
/sys/class/hwmon/hwmon8: coretemp
/sys/class/hwmon/hwmon9: it8613
```

列出hwmon9下的内容，查看支持情况  
```text
root@MEmini:~# ls /sys/class/hwmon/hwmon9/
alarms      in0_beep   in2_input  in5_max    in9_label                   pwm2_auto_start             pwm3_enable                 subsystem     temp2_max
device      in0_input  in2_max    in5_min    intrusion0_alarm            pwm2_enable                 pwm3_freq                   temp1_alarm   temp2_min
fan2_alarm  in0_max    in2_min    in7_alarm  name                        pwm2_freq                   pwm5                        temp1_beep    temp2_offset
fan2_beep   in0_min    in4_alarm  in7_beep   power                       pwm3                        pwm5_auto_channels_temp     temp1_input   temp2_type
fan2_input  in1_alarm  in4_beep   in7_input  pwm2                        pwm3_auto_channels_temp     pwm5_auto_point1_temp       temp1_max     temp3_alarm
fan2_min    in1_beep   in4_input  in7_label  pwm2_auto_channels_temp     pwm3_auto_point1_temp       pwm5_auto_point1_temp_hyst  temp1_min     temp3_beep
fan3_alarm  in1_input  in4_max    in7_max    pwm2_auto_point1_temp       pwm3_auto_point1_temp_hyst  pwm5_auto_point2_temp       temp1_offset  temp3_input
fan3_beep   in1_max    in4_min    in7_min    pwm2_auto_point1_temp_hyst  pwm3_auto_point2_temp       pwm5_auto_point3_temp       temp1_type    temp3_max
fan3_input  in1_min    in5_alarm  in8_input  pwm2_auto_point2_temp       pwm3_auto_point3_temp       pwm5_auto_slope             temp2_alarm   temp3_min
fan3_min    in2_alarm  in5_beep   in8_label  pwm2_auto_point3_temp       pwm3_auto_slope             pwm5_enable                 temp2_beep    temp3_offset
in0_alarm   in2_beep   in5_input  in9_input  pwm2_auto_slope             pwm3_auto_start             pwm5_freq                   temp2_input   uevent
```

查看风扇转速的示例
```shell
root@MEmini:~# cat /sys/class/hwmon/hwmon9/fan2_input 
1654
```

## 上游来源

- 驱动源码：[frankcrawford/it87](https://github.com/frankcrawford/it87)
