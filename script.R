#### INSTALL ssPopModel
# in the terminal, cd to where you save ssPopModel git repo.
# Then, type in the terminal: R CMD INSTALL ssPopModel
# NB: ssPopModel requires the package DEoptim to be installed, so make sure to install DEoptim package first

library(ssPopModel)

#John
path.to.data <- "~/ssPopModel_sensitivity_test/ssPopModel_sensitivity_test_data"
path.to.git.repository <- "~/ssPopModel_sensitivity_test"

#Francois
path.to.git.repository <- "~/Documents/DATA/Codes/ssPopModel_sensitivity_test"
path.to.data <- paste0(path.to.git.repository,"/ssPopModel_sensitivity_test_data")




# ## CREATE SIZE DISTRIBUTION
# #1. to download the data (using DAT)
# dat://456f261260e4ae8af7e7dc8b97fdabfdc770f561771e844888b1ef7f59a507ec
#
#2. calculate size distrubution
setwd(path.to.data)
popname <- "prochloro"
time.interval <- 60 #minutes
opp.dir <- "SCOPE_6_opp"
vct.dir <- "SCOPE_6_vct"
db <- "SCOPE_6.db"
inst <- "740"

for(width in seq(0.045,0.10,by=0.001)){
  distribution <- size.distribution(db=db, opp.dir=opp.dir, vct.dir=vct.dir, popname=popname, volume.width=width, time.interval = time.interval)
  save(distribution,file=paste0(path.to.git.repository,"/input_smooth/size.distribution_Prochlorococcus_",width))
}



setwd(path.to.git.repository)
Par <- read.csv("Par.csv")


## ESTIMATE GROWTH RATE for each width and various dt
list.dist  <- list.files("input_smooth", "size.distribution_Prochlorococcus",full.names=T)

for(dt in seq(5, 20, by=0.5)) {
    print(paste0("Time = ", dt))

    for(path.distribution in list.dist){
              #path.distribution <- list.dist[55]
              print(path.distribution)
              load(path.distribution)
              size <- unlist(list(strsplit(path.distribution, "_")))[4]
              freq.distribution <- as.matrix(distribution[[1]][37:61]) # size data for 1 day only
              Ntot <- as.vector(distribution[[2]][37:61])
              t <- 1
                    # calculating division rate based on size
                model1 <- run.ssPopModel(freq.distribution, Ntot, Par, time.delay=t, dt=dt)
                  save(model1, file=paste0('output_smooth/size_modeloutput_',size,"_dt_",dt))

                  # n.distribution <- freq.distribution %*% diag(Ntot)
                  # colnames(n.distribution) <- colnames(freq.distribution)
                  #plot.size.distribution(freq.distribution, mode="log", type="p", lwd=2)
                  #plot.size.distribution(n.distribution, mode="log", type="p", lwd=2)
    }
}









## MERGE MODEL OUTPUT (dt)
list.output <- list.files("output", "dt=",full.names=T)
DF <- NULL

for(path.distribution in list.output){
    #path.distribution <- list.output[1]
    print(path.distribution)
    load(path.distribution)
    size <- as.numeric(unlist(list(strsplit(path.distribution, "_")))[3])
    origin <- unlist(list(strsplit(basename(path.distribution), "_")))[1]
    dt <- as.numeric(unlist(list(strsplit(basename(path.distribution), "dt=")))[2])
    if(origin == "biomass"){
      params <- model2[,2][[1]]
      gr <- model2[,2][[2]]
    }
    if(origin == "size"){
      params <- model1[,2][[1]]
      gr <- model1[,2][[2]]
    }
    df <- data.frame(origin, size, dt, params,gr=sum(gr,na.rm=T))
    DF <- data.frame(rbind(DF, df))
}


## PLOTTING (dt)
par(mfrow=c(3,2),pty='m')
for(param in colnames(DF)[-c(1:3)]){
    #param <- 'gmax'
    plot(DF[which(DF$origin=="biomass"),"dt"], DF[which(DF$origin=="biomass"),param], ylim=c(range(DF[,param])),type='p',main=paste(param),ylab=NA, xlab=NA)
    points(DF[which(DF$origin=="size"),"dt"], DF[which(DF$origin=="size"),param],col=2,type='p')
}








## MERGE MODEL OUTPUT (size + dt)
list.output  <- list.files("output", "size_modeloutput",full.names=T)
DF <- NULL

for(path.distribution in list.output){
    #path.distribution <- list.output[1]
    #print(path.distribution)
    load(path.distribution)
    size <- as.numeric(unlist(list(strsplit(path.distribution, "_")))[3])
    origin <- unlist(list(strsplit(basename(path.distribution), "_")))[1]
    dt <-as.numeric(unlist(list(strsplit(basename(path.distribution), "_")))[4])
    if(is.na(dt)) next
    params <- model1[,2][[1]]
    gr <- model1[,2][[2]]

    df <- data.frame(origin, size, params,dt, gr=sum(gr,na.rm=T))
    DF <- data.frame(rbind(DF, df))
}


## PLOTTING
par(mfrow=c(3,2),pty='m')
for(param in colnames(DF)[-c(1:2)]){
    #param <- 'gmax'
    plot(DF[which(DF$origin=="biomass"),"size"], DF[which(DF$origin=="biomass"),param], ylim=c(range(DF[,param])),type='p',main=paste(param),ylab=NA, xlab=NA)
    points(DF[which(DF$origin=="size"),"size"], DF[which(DF$origin=="size"),param],col=2,type='p')
}

par(mfrow=c(1,1),cex=1.2)
plot(DF[which(DF$origin=="biomass"),"size"], abs(DF[which(DF$origin=="biomass"),param]-DF[which(DF$origin=="size"),param]),type='p',main=paste(param),ylab=NA, xlab=NA,cex=2)

#visualization
library(akima)
library(plotrix)
cols <- colorRampPalette(c("blue4","royalblue4","deepskyblue3", "seagreen3", "yellow", "orangered2","darkred"))

#plot(DF$size, DF$dt, col=cols(100)[cut(DF$gr,100)],pch=15, cex=1.4)

data <- interp(DF$size, DF$dt, DF$gr, duplicate="mean", nx=100)
data$z[which(data$z < 0)] <- NA # weird, min(data$z) < 0, need to check how is that even possible...

image(data, col=cols(100))
ylim <- par('usr')[c(3,4)]
xlim <- par('usr')[c(1,2)]
  color.legend(xlim[2], ylim[1], xlim[2] + 0.01*diff(xlim), ylim[2], legend=pretty(data$z), rect.col=cols(100), gradient='y',align='rb', cex=0.5)
points(DF$size, DF$dt, col='white',pch=16, cex=0.5)
