function vpn-down
    sudo systemctl stop xray
    sudo systemctl stop sing-box
    sudo systemctl start zapret2
    niri msg action spawn -- tg-ws-proxy
end
