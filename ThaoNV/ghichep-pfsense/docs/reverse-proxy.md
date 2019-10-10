# Hướng dẫn cấu hình pfsense làm reverse proxy

Trong bài này, mình sẽ sử dụng squid. Đây là package có thể sử dụng trên pfsense để làm cả proxy và reverse proxy.

Đầu tiên ta cần cài đặt squid trong package manager

<img src="https://i.imgur.com/kGEDPUo.png">

Sau đó ta vào Services->Squid Proxy và enable nó lên

<img src="https://i.imgur.com/7UnIXhW.png">

Trước khi mà cấu hình squid thì ta cần enable Local Cache trước. Ở đây mình để mặc định rồi save lại.

<img src="https://i.imgur.com/VCat8FI.png">

Sau đó ta tới tiếp phần `Service-Squid Reverse Proxy` trong tab Services

<img src="https://i.imgur.com/iWATGZn.png">

Chọn interface để listen, thường là WAN

Tiếp đó là domain hoặc ip

Ở phía dưới ta có lựa chọn để enable `Squid Reverse HTTP Settings` và `Squid Reverse HTTPS Settings` đi kèm với port listen. Khi define các port nhỏ hơn 1024 thì hệ thống có thể sẽ báo lỗi. Lỗi này báo bạn phải thay đổi giá trị của `net.inet.ip.portrange.reservedhigh` thành `0` trong `System-Advanced-System Tunables`. Nhưng giá tị này không có nên ta sẽ tạo nó bằng tay.

<img src="https://i.imgur.com/rs1R1B0.png">

Đối với https thì bạn cần phải có thêm cert.

Sau khi hoàn thành, ta chuyển qua tab Web Servers, tại đây ta sẽ define các server phía sau để pfsense đá vào bao gồm tên, ip và port

<img src="https://i.imgur.com/z3LtOoa.png">

Cuối cùng ta cần mapping, chuyển qua tap `Mappings` và lựa chọn các server đã define ở phần trước. Tại đây ta có thể map chính xác url bằng cách sử dụng regular expression.

<img src="https://i.imgur.com/mYAtL8S.png">

Save lại và nhớ mở rule firewall.
