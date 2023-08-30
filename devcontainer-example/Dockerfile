FROM frappe/bench:latest

# Configure apt
# ENV DEBIAN_FRONTEND=noninteractive

USER root

# install the tooks i wish to use
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -qq install zsh \
  wget \
  unzip \
  fonts-powerline

ENV FRAPPE_USER_NAME frappe
# ENV USER_NAME username
# ENV FRAPPE_USER_PASSWORD password
# ENV USER_PASSWORD password

# # add a user (--disabled-password: the user won't be able to use the account until the password is set)
# RUN adduser --quiet --disabled-password --shell /bin/zsh --home /home/$USER_NAME --gecos "User" $USER_NAME
# # update the password
# RUN echo "${FRAPPE_USER_NAME}:${FRAPPE_USER_PASSWORD}" | chpasswd && usermod -aG sudo $USER_NAME
# RUN echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd && usermod -aG sudo $USER_NAME
# RUN echo $USER_NAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER_NAME && chmod 0440 /etc/sudoers.d/$USER_NAME

# # # set home
ENV HOME /home/$FRAPPE_USER_NAME
# ENV HOME /home/$USER_NAME

USER $FRAPPE_USER_NAME
# USER $USER_NAME

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# Set the default shell to bash rather than sh
ENV SHELL /bin/zsh

 # run the installation script  
# RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O - | zsh || true

# install powerlevel10k
RUN git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

RUN cd $HOME && curl -fsSLO https://raw.githubusercontent.com/romkatv/dotfiles-public/master/.purepower


# installing nerd font
ENV FONTS_DIR ${HOME}/.local/share/fonts
RUN mkdir -p $FONTS_DIR
ENV ZIP_FILE FiraCode.zip
ENV VERSION v3.0.0
RUN wget https://github.com/ryanoasis/nerd-fonts/releases/download/$VERSION/$ZIP_FILE
RUN unzip $ZIP_FILE -d $FONTS_DIR
RUN rm $ZIP_FILE

# zsh configuration
ADD .zshrc $HOME

RUN nvm use 18