FROM linweiyuan/chatgpt-proxy-server-warp

ENV SUDO_USER_NAME dvc890
ENV MIRROR_URL 'https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch'

WORKDIR /app

RUN echo "Server = ${MIRROR_URL}" > /etc/pacman.d/mirrorlist \
    && pacman -Sy --needed --noconfirm \
    && pacman -S base-devel git --needed --noconfirm \
    && useradd -m ${SUDO_USER_NAME} \
    && echo "${SUDO_USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers \
    && su ${SUDO_USER_NAME} -c 'cd \
        && git clone https://aur.archlinux.org/google-chrome.git \
        && cd google-chrome \
        && source PKGBUILD \
        && sudo pacman -Syu --asdeps --needed --noconfirm "${makedepends[@]}" "${depends[@]}" \
        && makepkg -sir --noconfirm \
        && cd \
        && git clone https://github.com/ultrafunkamsterdam/undetected-chromedriver \
        && cd undetected-chromedriver \
        && sudo pacman -S --needed --noconfirm python python-setuptools \
        && sudo python setup.py install \
        && (python example/example.py &) \
        && while true; do [ -f ~/.local/share/undetected_chromedriver/undetected_chromedriver ] && sudo cp ~/.local/share/undetected_chromedriver/undetected_chromedriver / && break || sleep 1; done \
        && cd \
        && sudo rm -rf google-chrome undetected-chromedriver \
    ' \
    && pacman -Rs --noconfirm python-setuptools python git base-devel \
    && rm -rf /usr/lib/python* \
    && echo -e "y\nY" | pacman -Scc

RUN pacman -Sy --needed --noconfirm go
ENV PATH="/usr/local/go/bin:${PATH}"

EXPOSE 8080
EXPOSE 9515
EXPOSE 40000
EXPOSE 65535

ENV NETWORK_PROXY_SERVER socks5://0.0.0.0:65535
# ChatGPT proxy server address
ENV CHATGPT_PROXY_SERVER http://0.0.0.0:9515

COPY . .
RUN go build -ldflags="-w -s" -o go-chatgpt-api main.go

CMD ["bash", "-c", "/bin/bash /run.sh & sleep 3 && ../undetected_chromedriver --allowed-ips= --allowed-origins=* & sleep 5 && exec /app/go-chatgpt-api"]
