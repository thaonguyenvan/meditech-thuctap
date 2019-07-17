# Một số ghi chép về pacemaker trên CentOS 7

## 1. Tổng quan và kiến trúc

Tham khảo tại một số link sau:

- https://github.com/nguyenhungsync/Openstack_Research/blob/master/High-availability/3.%20Pacemaker/1.%20Intro-Pacemaker.md

- http://clusterlabs.org/pacemaker/doc/

### 1.1. Rule iptables

Mở all port

```
# firewall-cmd --permanent --add-service=high-availability
# firewall-cmd --add-service=high-availability
```

Các port này bao gồm

- TCP 2224 : Đây là port dành cho pcsd ui và giao tiếp giữa các node
- TCP 3121 : Dùng khi cluster có remote node. Daemon `crmd` sẽ giao tiếp với daemon `pacemaker_remoted` trên remote node thông qua port này.
- TCP 5403 : Yêu cầu đối với quorum device khi dùng với `corosync-qnetd`
- UDP 5404 : Yêu cầu đối với corosync node nếu corosync được cấu hình cho multicast UDP
- UDP 5405 : Yêu cầu trên tất cả các corosync node
- TCP 21064 : Yêu cầu trên tất cả các node nếu cluster chứa bất kì resource nào yêu cầu DLM (vd clvm hoặc GFS2)
- TCP 9929, UDP 9929

### 1.2 File config

Cso 2 file config chính là `corosync.conf` và `cib.xml`. Trong đó `corosync.conf` cung cấp các parameter dùng cho corosync. `cib.xml` là file xml chứa cả thông tin cấu hình và trạng thái hiện tại của resource trong cluster. Cả 2 file này đều được khuyến cáo là ko nên sửa bằng tay mà nên thông qua công cụ là command `pcs`.

## 2. `pcs` command line interface

### 2.1 pcs commands

Các pcs command bao gồm

- cluster
- resource
- stonith
- constraint
- property
- status
- config

### 2.2 pcs usage help

`pcs resource -h`

### 2.3 View raw config

`pcs cluster cib`

### 2.4 display status

`pcs status {commands}`

Trong đó có thể hiển thị trạng thái của `resources, groups, cluster, nodes, hoặc pcsd`

ví dụ

`pcs status nodes`

Hoặc cũng có thể không khai báo commands để hiển thị trạng thái chung.

### 2.5 Display full config

`pcs config`

### 2.6 display current pcs version

`pcs --version`

### 2.7 backup and restore config

`pcs config backup {filename}`

Để restore

`pcs config restore [--local] {filename}`

## 3. Tạo và quản lí cluster

Sau khi cài đặt, ta có thể tạo cluster và quản lí nó

### 3.1 Tạo cluster

Quá trình tạo cluster bao gồm các bước sau

#### 3.1.1 Start pcsd daemon

Chạy câu lệnh trên tất cả các node

```
# systemctl start pcsd.service
# systemctl enable pcsd.service
```

#### 3.1.2 Authen

- User name cho pcs là `hacluster`. Bạn nên set pass cho user này giống nhau trên các node
- Nếu bạn không cung cấp username và pass, hệ thống sẽ prompt

`pcs cluster auth [node] [...] [-u username] [-p password]`

Authorization token sẽ được lưu ở `~/.pcs/tokens` hoặc `/var/lib/pcsd/tokens`

#### 3.1.3 Configuring and Starting the Cluster Nodes

```
pcs cluster setup [--start] [--local] --name cluster_ name node1 [node2] [...]
pcs cluster start [--all] [node] [...]
```

### 3.2 Cấu hình timeout

Khi tạo cluster với câu lệnh `pcs cluster setup`, hệ thống sẽ sử dụng những thông số mặc định, bạn có thể thay đổi bằng cách thêm chúng vào câu lệnh trên.

- `--token timeout` : Thời gian time khi không nhận được token, mặc định là 1000ms
- `--join timeout` thời gian đợi join message, mặc định là 50 ms
- `--consensus timeout` : Thời gian để đạt được sự đồng thuận, mặc định là 1200s

Ví dụ

`pcs cluster setup --name new_cluster nodeA nodeB --token 10000 --join 100`

### 3.3 Quản lý cluster node

#### 3.3.1 Dừng cluster services

`pcs cluster stop [--all] [node] [...]`

Nếu bạn không chỉ định node, nó sẽ dừng ở node local

Bạn có thể force tắt cluster service ở local bằng câu lệnh

`pcs cluster kill`

Câu lệnh này tương đương `kill -9`

**Lưu ý:**

Bạn có thể dùng câu lệnh stop start để chuyển resource qua lại giữa các node.

#### 3.3.2 Enabling and Disabling Cluster Services

Cấu hình cluster khởi động cùng hệ thống

`pcs cluster enable [--all] [node] [...]`

Cấu hình không khởi động cùng hệ thống

`pcs cluster disable [--all] [node] [...]`

#### 3.3.3 Thêm node

Trên node mới, ta cần thực hiện một số thao tác sau

- Cài package

`yum install -y pcs pacemaker fence-agents-all`

- Thêm rule firewall

```
# firewall-cmd --permanent --add-service=high-availability
# firewall-cmd --add-service=high-availability
```

- Đặt pass cho user `hacluster`

`passwd hacluster`

- start service

```
# systemctl start pcsd.service
# systemctl enable pcsd.service
```

Trên node đã thuộc cluster, thực hiện một số thao tác sau

- Authen user trên node mới

`pcs cluster auth newnode`

- Add node mới, command này sẽ sync cấu hình trong file `corosync.conf` tới tất cả các node trong cluster

`pcs cluster node add `

- start và enable cluster service trên node mới

```
pcs cluster start newnode
pcs cluster enable newnode
```

#### 3.3.4 Remove node

`pcs cluster node remove nodename`

Nếu node đã down, thêm tùy chọn `--force` vì câu lệnh này sẽ đồng bộ file corosync.conf nên có thể có một số cảnh báo timeout nếu node đã down

#### 3.3.5 Stanby node

Nếu đưa vào trạng thái standby thì node sẽ không thể chứa resource nữa, nếu đang có resource, nó sẽ được chuyển qua các node còn lại

`pcs cluster standby node | --all`

Remove trạng thái standby

`pcs cluster unstandby node | --all`

### 3.4 Remove cluster config

`pcs cluster destroy`

## 4. Config resource

### 4.1. Tạo resource

```
pcs resource create resource_id [standard:[provider:]]type [resource_options] [op operation_action operation_options [operation_action operation options]...] [meta meta_options...] [clone [clone_options] | master [master_options] | --group group_name [--before resource_id | --after resource_id] | [bundle bundle_id] [--disabled] [--wait[=n]]
```

- `--before` và `--after` để chỉ định vị trí đối với resource đã được add trước đó

- `--disabled` để chỉ định resource đó sẽ không được start tự động

Dưới đây là ví dụ về việc tạo resource vip của ocf, ip là `192.168.0.120` và hệ thống sẽ check mỗi 30s

```
# pcs resource create VirtualIP ocf:heartbeat:IPaddr2 ip=192.168.0.120 cidr_netmask=24 op monitor interval=30s
```

Để xóa resource

`pcs resource delete resource_id`

### 4.2 Resource properties

- `resource_id` : Tên resource mà bạn đặt
- `standard` : standard . bao gồm `ocf, service, upstart, systemd, lsb, stonith`
- `type` : Tên resource agent
- `provider` : tên provider

Một số command để display resource

- `pcs resource list` : Hiển thị toàn bộ resource
- `pcs resource standards` : danh sách resources agent standards
- `pcs resource providers` : Danh sách resources agent providers

### 4.3 Resource groups

Trong trường hợp resource phải được đặt cạnh nhau, start theo thứ tự và stop theo thứ tự ngược lại thì bạn có thể sử dụng group

```
pcs resource group add group_name resource_id [resource_id] ... [resource_id]
[--before resource_id | --after resource_id
```

Trường hợp mà group chưa có thì nó sẽ tạo group, còn nếu có rồi thì nó sẽ adđ thêm resource vào.

Để xóa resource group

`pcs resource group remove group_name resource_id...`

Để list tất cả các resource group

`pcs resource group list`

Ta lấy ví dụ:

`pcs resource group add shortcut IPaddr Email`

Các quy tắc mà resource group này tạo ra:

- IPaddr sẽ start trc rồi tới Email
- Email sẽ stop trước rồi tới IPaddr
- Nếu IPaddr không thể chạy được, thì Email cũng vậy
- Nếu Email không thể chạy được thì nó không ảnh hưởng tới IPaddr

### 4.4 Resource operations

- Các trường báo gồm:

  - id : Tên duy nhất cho hành động
  - name : Hành động để thực hiện, các giá trị phổ biến bao gồm `monitor, start, stop`
  - interval : Thời gian mà hành động được lặp lại
  - timeout : Nếu hành động không thực hiện được sau khoảng thời gian này, hủy hành động và báo fail
  - on-fail : Các hành động thực hiện nếu action fail
    - ignore : Coi như action chưa fail
    - block : Không thực hiện thêm bất cứ action nào với resource
    - stop : Dừng resource và ko cho nó start nữa
    - restart : Dừng resource và khởi động lại
    - standby : Chuyển tất cả resource sang node khác
  - enabled : Nếu giá trị là `false` thì resource này được coi như không tồn tại

#### 4.4.1 Configuring Resource Operations

Bạn có thể cấu hình nó khi tạo resource. Ta lấy ví dụ tạo `IPaddr2` resource với monitor action. Resource được monitor mỗi 30s.

```
# pcs resource create VirtualIP ocf:heartbeat:IPaddr2 ip=192.168.0.99 cidr_netmask=24 nic=eth2 op monitor interval=30s
```

Hoặc ta có thể add action với các resource đã tồn tại

`pcs resource op add resource_id operation_action [operation_properties]`

Để xóa cấu hình operation của resource

`pcs resource op remove resource_id operation_name operation_properties`

Để update

`pcs resource update VirtualIP op stop interval=0s timeout=40s`

#### 4.4.2 Configuring Global Resource Operation Defaults

Để set default

`pcs resource op defaults [options]`

Để hiển thị các giá trị default hiện tại

`pcs resource op defaults`

### 4.5 Display configured resource

Hiển thị danh sách các resource đã cấu hình

`pcs resource show`

có thể dùng thêm option `--full` để hiển thị cả các parameter.

Để hiển thị cấu hình chi tiết của 1 resource

`pcs resource show resource_id`

### 4.6 Modify resource config

Update cấu hình resource

`pcs resource update resource_id [resource_options]`

ví dụ

`pcs resource update VirtualIP ip=192.169.0.120`

### 4.7 Enable & Disable cluster resource

```
pcs resource enable resource_id
pcs resource disable resource_id
```

### 4.8 Resource cleanup

Khi resource fail, sẽ có message fail được hiển thị. Nếu bạn đã giải quyết được vấn đề, bạn có thể clear trạng thái đó với câu lệnh

`pcs resource cleanup`

Câu lệnh này sẽ reset trạng thái resource và đếm số lần fail,  cluster quên đi lịch sử và detect lại trạng thái hiện tại.

## 5. Resource constraint

### 5.1 Location Constraints

Cấu hình này cho phép resource yêu thích hoặc tránh node nào đó, có nghĩa là nó ảnh hưởng tới nơi đặt resource. Với value là `score` để chỉ ra mức độ ưu tiên.

```
pcs constraint location rsc prefers node[=score] [node[=score]] ...
pcs constraint location rsc avoids node[=score] [node[=score]] ...
```

Mặc định nếu không khai báo giá trị score sẽ là `INFINITY`. Giá trị này không loại bỏ việc resource sẽ có thể chạy trên các node khác.

### 5.2 Order Constraints

Cấu hình này ảnh hưởng tới thứ tự chạy resource.

`pcs constraint order [action] resource_id then [action] resource_id [options]`

Trong đó:

- `resource_id` : Tên resource
- `action` : Hành động, bao gồm
  - `start`
  - `stop`
  - `promote` : promote resource từ slave resource thành master resource
  - `demote` : ngược lại với promote
- `kind` : có 2 option
  - `Optional` : chỉ áp dụng nếu cả 2 resource cùng thực hiện 1 hành động
  - `Mandatory` : là giá trị mặc định, luôn thực hiện

Xóa resource order

`pcs constraint order remove resource1 [resourceN]...`

### 5.3 Colocation constraint

Xác định vị trí của resource dựa vào sự ràng buộc với resource khác. Lưu ý rằng nó sẽ ảnh hưởng tới thứ tự của resource và cả location. Ví dụ bạn colocate resource A vs B thì A sẽ quyết định cho việc chọn node thay vì B.

`pcs constraint colocation add [master|slave] source_resource with [master|slave] target_resource [score] [options]`

Trong đó :

- `source_resource` : Colocation source
- `target_resource` : Colocation target
- `score` : Giá trị dương thì 2 resource sẽ chạy trên cùng 1 node, âm thì chạy khác node, mặc định là `+INFINITY` nghĩa là chạy cùng node.

ví dụ:

`# pcs constraint colocation add myresource1 with myresource2 score=INFINITY`

Xóa colocation constraint

`pcs constraint colocation remove source_resource target_resource`

### 5.4 Display constraint

`pcs constraint list|show`

## 6. Quản lý resource

### 6.1 Moving around

`pcs resource move resource_id [destination_node] [--master] [lifetime=lifetime]`

### 6.2 Moving due to failure

Như đã biết, resource có thể được đếm số lần fail. Ta có thể dùng số lần fail này để làm thông tin cho việc chuyển resource qua node khác. Ta có thông số migration threshold, ví dụ ở đây là 10 thì nó sẽ chuyển resource đi sau 10 lần fail.

`pcs resource meta dummy_resource migration-threshold=10`

### 6.3 Enable, disable, ban resource

Để stop resource:

`pcs resource disable resource_id [--wait[=n]]`

Nếu khai báo thêm `--wait` thì pcs sẽ đợi tối đa `n` giây để resource được tắt. Mặc định thì con số đó là 60 phút.

Để start resource

`pcs resource enable resource_id [--wait[=n]]`

Để ngăn việc resource chạy trên node chỉ định

`pcs resource ban resource_id [node] [--master] [lifetime=lifetime] [--wait[=n]]`

Thực chất câu lệnh trên sẽ add 1 location constraint với giá trị là `-INFINITY` tức là ngăn chặn resource không chạy trên node đó.

Bạn có thể dùng câu lệnh `pcs resource clear` hoặc `pcs constraint delete` để xóa constraint

Ngoài ra câu lệnh `debug-start` có thể dùng để buộc resource start trên node hiện tại, thường được dùng để debug.

`pcs resource debug-start resource_id`

### 6.4 Disable monitor operation

Cách dễ nhất để dừng monitor là xóa nó đi, tuy nhiên nếu bạn chỉ muốn tạm thời dừng nó thì bạn có thể dùng câu lệnh sau

`# pcs resource update resourceXZY op monitor enabled=false`

Để enable trở lại

`# pcs resource update resourceXZY op monitor enabled=true`

Tuy nhiên, lưu ý rằng khi enable trở lại thì các options bạn set trước đó sẽ được đưa về mặc định.

### 6.5 Manage resource

Bạn có thể set resource vào mode `unmanaged`, lúc này thì resource sẽ vẫn ở trong cấu hình nhưng Pacemaker sẽ không quản lí nó nữa.

`pcs resource unmanage resource1  [resource2] ...`

Để quay trở lại manage mode

`pcs resource manage resource1  [resource2] ...`
