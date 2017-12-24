FROM debian

MAINTAINER Aaron McKenna <aaronmck@uw.edu>

# basic setup -- update the instance
# ################################################
RUN apt-get update
RUN apt-get install -y apt-transport-https
RUN mkdir -p /usr/share/man/man1

# add basic tools to the instance, including sbt
# ################################################
RUN apt-get install -y default-jre wget unzip net-tools emboss scala gnupg2 bash make gcc g++ zlib1g-dev

RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
RUN apt-get update
RUN apt-get install -y sbt

RUN wget -O sbt.zip https://github.com/sbt/sbt/releases/download/v1.0.4/sbt-1.0.4.zip

RUN apt-get install -y openssh-server

# install GESTALT scripts and tools
# ################################################

RUN git clone https://github.com/aaronmck/SC_GESTALT.git /app/sc_GESTALT

RUN mkdir /app/data
RUN mkdir /app/bin

# remaining tools to install:
# - path for scala
# ################################################
RUN wget -q -O /app/Trimmomatic.zip http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.36.zip

RUN unzip -d /app/ /app/Trimmomatic.zip

RUN cp /app/Trimmomatic-0.36/trimmomatic-0.36.jar /app/bin/trimmomatic.jar

RUN wget -q -O /app/flash.tar.gz https://sourceforge.net/projects/flashpage/files/FLASH-1.2.11.tar.gz/download

RUN tar xCf /app /app/flash.tar.gz

RUN cd /app/FLASH-1.2.11/ && make

RUN cp /app/FLASH-1.2.11/flash /usr/local/bin/


# get the data for the example run
# ################################################

RUN wget -q -O /app/data/Dome_stage_N4_1X.fastq1.fq.gz http://krishna.gs.washington.edu/content/members/aaron/fate_map/all_trees/data/Dome_4_1x.barcodeSplit.fastq1.fq.gz
RUN wget -q -O /app/data/Dome_stage_N4_1X.fastq2.fq.gz http://krishna.gs.washington.edu/content/members/aaron/fate_map/all_trees/data/Dome_4_1x.barcodeSplit.fastq2.fq.gz

RUN mkdir /app/references/
RUN wget --recursive --no-parent --directory-prefix=/app/references/ http://krishna.gs.washington.edu/content/members/aaron/fate_map/all_trees/data/target1_25mer_outer/
RUN wget -q -O /app/queue.jar http://krishna.gs.washington.edu/content/members/aaron/fate_map/all_trees/data/gatk-queue-package-distribution-3.5.jar
RUN wget -q -O /app/sc_GESTALT/Maul.jar https://github.com/aaronmck/Maul/releases/download/1.0/Maul-assembly-1.0.jar
RUN wget -q -O /app/EDNAFULL.Ns_are_zero http://krishna.gs.washington.edu/content/members/aaron/fate_map/all_trees/data/EDNAFULL.Ns_are_zero

RUN mkdir /var/run/sshd

RUN chmod 0755 /var/run/sshd
RUN /usr/sbin/sshd

RUN useradd --create-home --shell /bin/bash --groups sudo gestalt ## includes 'sudo'
# RUN echo "gestalt1" | passwd gestalt --stdin ## Enter a password
RUN echo "gestalt:gestalt1" | chpasswd
RUN ifconfig | awk '/inet addr/{print substr($2,6)}' ## Display IP address (optional)

# setup the various tools
RUN cd /app/sc_GESTALT/UMIMerge && sbt -Dbuild.tool=call assembly
RUN cd /app/sc_GESTALT/UMIMerge && sbt -Dbuild.tool=umi assembly

RUN cp /app/sc_GESTALT/UMIMerge/target/scala-2.12/DeepSeq.jar /app/bin 
RUN cp /app/sc_GESTALT/UMIMerge/target/scala-2.12/UMIMerge.jar /app/bin

# setup the webpage
# #################################################
RUN apt-get install -y lighttpd

RUN cp /app/sc_GESTALT/www/lighttpd.conf /etc/lighttpd/lighttpd.conf