# Steven Martell
# Aug 31,  2012

.plotSpawnBiomass <- function( M )
{
	n <- length(M)
	cat(".plotSpawnBiomass\n")

	mdf <- NULL
	for(i in 1:n)
	{
		fit = M[[i]]$fit
		yr  = M[[i]]$yr
		nyr = length(yr)
		log.sbt <- fit$est[fit$names=="sd_log_sbt"][1:nyr]
		log.std <- fit$std[fit$names=="sd_log_sbt"][1:nyr]
		bt <- data.frame(Model=names(M)[i],Year=yr,log.sbt=log.sbt,log.se=log.std)
		bt <- data.frame(bt,Bo=M[[i]]$bo)
		mdf <- rbind(mdf,bt)
	}

	if(.OVERLAY)
	{
		p <- ggplot(mdf,aes(Year,exp(log.sbt),col=Model)) + geom_line(width=2)
		p <- p + geom_ribbon(aes(ymax=exp(log.sbt+1.96*log.se),
		                     ymin=exp(log.sbt-1.96*log.se),fill=Model),alpha=0.2)
	}
	else
	{
		p <- ggplot(mdf,aes(Year,exp(log.sbt))) + geom_line(width=2)
		p <- p + geom_ribbon(aes(ymax=exp(log.sbt+1.96*log.se),
		                     ymin=exp(log.sbt-1.96*log.se)),alpha=0.2)
		p <- p + facet_wrap(~Model,scales="free")
	}
	# p <- p + geom_line(data=bt,aes(Year,Bo),col="blue")
	p <- p + labs(x="Year",y=paste("Spawning biomass",.UNITS))
	print(p + .THEME)
}


# .plotBiomass	<- function( repObj, annotate=FALSE )
# {
# 	#plot total biomass & spawning biomass 
# 	with(repObj, {
# 		xx=yr
# 		yy=cbind(bt[1:length(xx)], sbt[1:length(xx)])
		
# 		yrange=c(0, 1.2*max(yy, na.rm=TRUE))
		
# 		matplot(xx, yy, type="n",axes=FALSE,
# 				xlab="Year", ylab="Biomass (1000 t)",main=paste(stock), 
# 				ylim=yrange)
		
# 		matlines(xx,yy,
# 			type="l", col="black",
# 			ylim=c(0,max(yy,na.rm=T)))
# 		axis( side=1 )
# 		axis( side=2, las=.VIEWLAS )
# 		box()
# 		grid()
		
# 		if ( annotate )
# 		{
# 			mfg <- par( "mfg" )
# 			if ( mfg[1]==1 && mfg[2]==1 )
# 			legend( "top",legend=c( "Pre-fishery biomass","Spawning biomass"),
# 				bty='n',lty=c(1,2),lwd=c(1,1),pch=c(-1,-1),ncol=1 )
# 		}
# 	})	
# }
