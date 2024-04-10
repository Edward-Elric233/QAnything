ARG PIP_OPTIONS="-i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn"
FROM opencloudos/opencloudos:8.8

# 设置非交互式前端，防止在安装过程中出现交云提示
ENV DEBIAN_FRONTEND=noninteractive

RUN dnf update -y && dnf install -y wget tar gcc zlib zlib-devel bzip2 bzip2-devel ncurses ncurses-devel readline readline-devel openssl openssl-devel xz xz-devel sqlite sqlite-devel gdbm gdbm-devel tk tk-devel mysql-devel libffi-devel make mesa-libGL lsof gzip

RUN mkdir /build && cd /build && wget https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz && tar -xvf Python-3.10.12.tgz && cd Python-3.10.12 && ./configure && make all && make install && ln -s /usr/local/bin/python3 /usr/bin/python3 && ln -s /usr/local/bin/pip3 /usr/bin/pip

RUN python3 -m pip install $PIP_OPTIONS --upgrade pip && pip install $PIP_OPTIONS --no-cache-dir --extra-index-url https://pypi.ngc.nvidia.com regex==2023.10.3 fire==0.5.0 && \
    pip install $PIP_OPTIONS --no-cache-dir modelscope==1.13.0 \
                                            Pillow==10.2.0 \
                                            numpy==1.24.3 \
                                            PyMuPDF==1.20.2 \
                                            easyocr==1.7.1 \
                                            # onnxruntime==1.17.1 \
                                            transformers==4.38.2 \
                                            vllm==0.3.3 \
                                            openai==1.12.0 \
                                            concurrent-log-handler==0.9.25 \
                                            sentencepiece==0.1.99 \
                                            tiktoken==0.4.0 \
                                            sanic==23.6.0 \
                                            sanic_ext==23.6.0 \
                                            milvus>=2.3.5 \
                                            pymilvus>=2.3.7 \
                                            langchain==0.1.9 \
                                            pypinyin==0.50.0 \
                                            unstructured==0.12.4 \
                                            unstructured[pptx]==0.12.4 \
                                            unstructured[md]==0.12.4 \
                                            accelerate==0.21.0 
    
# Add FT-backend

ENV WORKSPACE /workspace
WORKDIR /workspace

# 下载Node.js指定版本的压缩包
RUN wget https://nodejs.org/download/release/v18.19.0/node-v18.19.0-linux-x64.tar.gz

# 创建目录用于存放Node.js
RUN mkdir -p /usr/local/lib/nodejs

# 解压Node.js压缩包到指定目录
RUN tar -zxvf node-v18.19.0-linux-x64.tar.gz -C /usr/local/lib/nodejs

# 设置环境变量，将Node.js的bin目录加入到PATH中
ENV PATH="/usr/local/lib/nodejs/node-v18.19.0-linux-x64/bin:${PATH}"

RUN rm /workspace/node-v18.19.0-linux-x64.tar.gz

RUN mkdir /opt/tiktoken_cache
ARG TIKTOKEN_URL="https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken"
RUN wget -O /opt/tiktoken_cache/$(echo -n $TIKTOKEN_URL | sha1sum | head -c 40) $TIKTOKEN_URL
ENV TIKTOKEN_CACHE_DIR=/opt/tiktoken_cache
# 启动nginx
# CMD ["nginx", "-g", "daemon off;"]
