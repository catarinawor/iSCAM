#helpers.R
# LIBRARIES
library(markdown)
library(shiny)
library(ggplot2)
library(reshape2)
# library(googleVis)
# library(plyr)
library(Rcpp)
library(dplyr)
library(magrittr)
library(grid)
# library(leaflet)
# library(maps)


sourceCpp("data/src/halitosis.cpp")






# 
# LOAD A mse.data DATA OBJECT
# 
load("data/MSE.Rdata")  

# 
# LOAD data from assessment model
# 
load("data/OMI.Rdata")


# 
# LOAD data from halibut size-at-age (par.df Object)
# 
load("data/halibutSAA.Rdata")


# 
# LOAD estimated growth parameters from 2014 SAA data.
#
load("data/halGrowthParams.Rdata")
.REGAREA <- c("all","2A","2B","2C","3A","3B","4A","4B","4CDE")


.THEME      <- theme_bw(11)
.OVERLAY    <- FALSE
.UNITS		<- "(Mlb)"
.LIB        <- "data/lib/"
.RFILES     <- list.files(.LIB,pattern="\\.[Rr]$")
for(nm in .RFILES) source(file.path(.LIB, nm), echo=FALSE)



paramNames <- c("size_limit",
                "discard_mortality_rate",
                "selex_fishery",
                "selex_bycatch",
                "selex_bycatch_desc",
                "num_bycatch",
                "five",
                "ten",
                "twenty",
                "forty",
                "regArea",
                "linf_dev",
                "vonk_dev",
                "maternal_effect")


tulip.plot <- function(df,input)
{
	.LEGPOS <- 'bottom'

	print(input$plotType)
	icol <- c("Scenario","Procedure","Year","gear","area","sex","group")
	if(input$plotType=='Spawning biomass')
	{
		icol <- c(icol,"t.Bt0.5","t.Bt0.025","t.Bt0.975")
	}
	if(input$plotType=='Depletion')
	{
		icol <- c(icol,"t.Dt0.5","t.Dt0.025","t.Dt0.975")	
	}
	if(input$plotType=='Catch')
	{
		icol <- c(icol,"ct50","ct025","ct975")
	}
	if(input$plotType=='Sub-legal Catch')
	{
		icol <- c(icol,"dt50","dt025","dt975")	
	}
	if(input$plotType=='Sub-legal Catch')
	{
		icol <- c(icol,"dt50","dt025","dt975")	
	}
	if(input$plotType=='AAV in Catch')
	{
		icol <- c(icol,"AAV50","AAV025","AAV975")
	}
	if(input$plotType=='Wastage')
	{
		icol <- c(icol,"wt50","wt025","wt975")	
	}
	if(input$plotType=='Efficiency')
	{
		icol <- c(icol,"ef50","ef025","ef975")	
	}
	if(input$plotType=='Fishing mortality')
	{
		icol <- c(icol,"Ft0.5","Ft0.025","Ft0.975")
	}
	sdf  <- df[,which(names(df) %in% icol)]
	n    <- dim(sdf)[2] - 2
	colnames(sdf)[n:(n+2)] <- c("lci","Median","uci")

	print(tail(sdf))

	# GGPLOT.
	ci <- aes(ymin=lci,ymax=uci)
	p <- ggplot(sdf,aes(x=Year,y=Median)) + geom_line()
	p <- p + geom_ribbon(ci,alpha=0.25)
	p <- p + labs(x="Year",y=input$plotType)

	if( input$icolor != "." )
	{
		p <- p + aes_string(fill=input$icolor,color=input$icolor)
	}

	facets <- paste(input$facet_row,"~",input$facet_col)
	p      <- p + facet_grid(facets)


	print(p + theme( legend.position = .LEGPOS ) )
	
}


# GOOGLE VIS MOTION PLOT
motionChart <- function(df,input)
{
	M1 <- gvisMotionChart(df,idvar="idvar",timevar="Year",
	                      xvar="Depletion",yvar="Median catch",
	                      sizevar="Median AAV",colorvar="Procedure",
	      options=list(showChartButtons = TRUE))
	return(M1)
}


