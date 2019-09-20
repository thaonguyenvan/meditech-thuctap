# Hướng dẫn check pfsense

### 1. Cài đặt agent

- Bật ssh và ssh vào pfsense và truy cập vào shell

- Cài bash

`pkg install -y bash`

- Check thử  bằng cách gõ `bash`. Nếu gặp lỗi

`Shared object "libdl.so.1" not found, required by "bash"`

Ta sẽ fix bằng một trick nhỏ

`ln -sf /lib/libc.so.7 /usr/lib/libdl.so.1`

- Tạo 2 folder

```
mkdir -p /opt/bin
mkdir -p /opt/etc/xinetd.d
```

- Tải về checkmk agent

```
curl --output /opt/bin/check_mk_agent https://raw.githubusercontent.com/tribe29/checkmk/master/agents/check_mk_agent.freebsd
chmod +x /opt/bin/check_mk_agent
```

- Tạo file xinetd

`vi /opt/etc/xinetd.d/check_mk`

```
service check_mk
{
    type           = UNLISTED
    port           = 6556
    socket_type    = stream
    protocol       = tcp
    wait           = no
    user           = root
    server         = /opt/bin/check_mk_agent

    # If you use fully redundant monitoring and poll the client
    # from more then one monitoring servers in parallel you might
    # want to use the agent cache wrapper:&lt;br /&gt;

    #server         = /usr/bin/check_mk_caching_agent

    # configure the IP address(es) of your Nagios server here:
    #only_from      = 127.0.0.1 10.0.20.1 10.0.20.2

    # Don't be too verbose. Don't log every check. This might be
    # commented out for debugging. If this option is commented out
    # the default options will be used for this service.
    log_on_success =

    disable        = no
}
```

Thêm dòng này vào file `/etc/inc/filter.inc` trước dòng số 2380

`fwrite($xinetd_fd, "includedir /opt/etc/xinetd.d");`

```
vi /etc/inc/filter.inc
(...)    }
    fwrite($xinetd_fd, "includedir /opt/etc/xinetd.d");
    fclose($xinetd_fd); // Close file handle
(...)
```

- Kích hoạt

Vào pfSense GUI tới tab Status->Filter Reload

- Check lại từ phía check mk

```
telnet 192.168.0.250 6556
```

Nếu script chạy ok

```
[root@compute ~]# telnet 192.168.100.110 6556
Trying 192.168.100.110...
Connected to 192.168.100.110.
Escape character is '^]'.
<<<check_mk>>>
Version: 1.7.0i1
AgentOS: freebsd
Hostname: pfSense.localdomain
AgentDirectory: /etc/check_mk
DataDirectory:
SpoolDirectory:
PluginsDirectory: /usr/local/lib/check_mk_agent/plugins
LocalDirectory: /usr/local/lib/check_mk_agent/local
<<<df>>>
/dev/gptid/f14922b7-cdf1-11e9-aa79-000c29927548  ufs     47732604 782644 43131352     2%    /
/dev/md0                                         ufs         3484     92     3116     3%    /var/run
<<<zfsget>>>
[df]
<<<zfs_arc_cache>>>
demand_hit_predictive_prefetch = 0
sync_wait_for_async = 0
arc_meta_min = 79893760
arc_meta_max = 0
arc_meta_limit = 319575040
arc_meta_used = 0
memory_throttle_count = 0
l2_write_buffer_list_null_iter = 0
l2_write_buffer_list_iter = 0
l2_write_buffer_bytes_scanned = 0
```

### 2. Bật snmp

- Vô dashboard, Services->SNMP

Check vào `Enable the SNMP Daemon and its controls`.

Điền các thông tin như port, string và chọn interface binding (thường là LAN)

<img src="https://i.imgur.com/UlkCFXW.png">

Save lại

### 3. Add host ở phía check mk

<img src="https://i.imgur.com/3U6BZlB.png">

Kiểm tra

<img src="https://i.imgur.com/fCVVChw.png">


### Tham khảo

https://daysofthunderblog.wordpress.com/2018/07/03/install-check_mk-agent-on-pfsense/

https://openschoolsolutions.org/pfsense-monitoring-check-mk/

https://superuser.com/questions/1309186/managing-freebsd-host-with-ansible-fails-shared-object-libdl-so-1-not-found

https://support.auvik.com/hc/en-us/articles/360000932806-How-to-enable-SNMP-on-a-pfSense-device

https://github.com/tribe29/checkmk
