function vpn-up
    switch "$argv[1]"
        case xray
            switch "$argv[2]"
                case hysteria vless
                    sudo ln -sf /etc/xray/profiles/$argv[2].conf /etc/xray/config.json
                case '*'
                    echo "Usage: vpn-up xray hysteria|vless"
                    return 1
            end
            sudo systemctl stop sing-box
            sudo systemctl stop zapret2
            pkill tg-ws-proxy 2>/dev/null
            sudo systemctl start xray
        case sing-box
            sudo systemctl start sing-box
            sudo systemctl stop zapret2
            pkill tg-ws-proxy
        case '*'
            echo "Usage: vpn-up sing-box | xray hysteria|vless"
            return 1
    end
end
