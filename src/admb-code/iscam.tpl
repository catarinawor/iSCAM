/// @file iscam.tpl
/// @author Steve Martell, IPHC

///
/// \def REPORT(object)
/// \brief Prints name and value of \a object on ADMB report %ofstream file.
///

///
/// \def COUT(object)
/// \brief Screen dump using cout<<"object\n"<<object<<endl;
///

///
/// \def TINY
/// \brief A small number (1.e-08)`
///

// ----------------------------------------------------------------------------- //
//         integrated Statistical Catch Age Model (iSCAM)                        //
//                                                                               //
//                           VERSION 1.1                                         //
//               Tue Jul 19 22:23:58 PDT 2011                                    //
//                                                                               //
//                                                                               //
//           Created by Steven Martell on 2010-04-09                             //
//           Copyright (c) 2010. All rights reserved.                            //
//                                                                               //
// AUTHORS: SJDM Steven Martell                                                  //
//                                                                               //
// CONVENTIONS: Formatting conventions are based on the The                      //
//               Elements of C++ Style (Misfeldt et al. 2004)                    //
//                                                                               //
// NAMING CONVENTIONS:                                                           //
//             Macros       -> UPPERCASE                                         //
//             Constants    -> UpperCamelCase                                    //
//             Functions    -> lowerCamelCase                                    //
//             Variables    -> lowercase                                         //
//                                                                               //
// CHANGED add option for using empirical weight-at-age data                     //
// TODO:   ? add gtg options for length based fisheries                          //
// CHANGED add time varying natural mortality rate with splines                  //
// TODO:   ? add cubic spline interpolation for time varying M                   //
// CHANGED  Fix the type 6 selectivity implementation. not working.              //
// TODO:  fix cubic spline selectivity for only years when data avail            //
// CHANGED: fixed a bug in the simulation model log_ft_pars goes out             //
//        of bounds.                                                             //
// TODO: write a projection routine and verify equilibrium calcs                 //
// TODO: add DIC calculation for MCMC routines (in -mcveal phase)                //
// CHANGED: add SOK fishery a) egg fishing mort 2) bycatch for closed ponds      //
//                                                                               //
// TODO: correct the likelihood function as per Roberto's email. See Schnute     //
//       and Richards (1995) paper. Table 4 when 0<rho<1                         //
//                                                                               //
// TODO: Check the recruitment autocorrelation residuals & likelihood.           //
//                                                                               //
//                                                                               //
// ----------------------------------------------------------------------------- //
//-- CHANGE LOG:                                                               --//
//--  Nov 30, 2010 -modified survey biomass by the fraction of total           --//
//--                mortality that occurred during the time of the             --//
//--                survey. User specifies this fraction (0-1) in the          --//
//--                data file as the last column of the relative               --//
//--                abundance index.                                           --//
//--                                                                           --//
//--  Dec 6, 2010 -modified the code to allow for empiracle weight-            --//
//--               at-age data to be used.                                     --//
//--              -rescaled catch and relative abundance /1000, this           --//
//--               should be done in the data file and not here.               --//
//--                                                                           --//
//--  Dec 20, 2010-added prior to survey q's in control file                   --//
//--                                                                           --//
//--  Dec 24, 2010-added random walk for natural mortality.                    --//
//--                                                                           --//
//--  Jan 23, 2011-in Penticton Hospital with my mom in ICU, adopting          --//
//--               the naming conventions in The Elements of C++               --//
//--               style to keep my mind busy.                                 --//
//--                                                                           --//
//-- May 5, 2011- added logistic selectcitivty as a fucntion of                --//
//--              mean body weight.  3 parameter logistic.                     --//
//--              NOT WORKING YET                                              --//
//--                                                                           --//
//-- May 6, 2011- added pre-processor commands to determin PLATFORM            --//
//--              either "Windows" or "Linux"                                  --//
//--            - change April 10, 2013 to #if defined _WIN32 etc.             --//
//--                                                                           --//
//--                                                                           --//
//-- use -mcmult 1.5 for MCMC with log_m_nodes with SOG herrning               --//
//--                                                                           --//
//--                                                                           --//
//-- Dec 11, 2011- added halibut branch to local git repository aim is to      --//
//--               add gender dimension and stock dimension.                   --//
//--               This was created on the "twosex" branch in git merged       --//
//--                                                                           --//
//-- Dec 30, 2011- working on length-based selectivity for halibut.            --//
//--                                                                           --//
//-- Jan 5, 2012 - adding spawn on kelp fishery as catch_type ivector          --//
//--             - modified the following routines:                            --//
//--             - calcCatchAtAge                                              --//
//--             - calcTotalMortality                                          --//
//--                                                                           --//
//-- Oct 31,2012 - added penalty to time-varying changes in selex for          --//
//--             - isel_type 4 and 5 cases in the objective function.          --//
//--             - Requires and additional input in the control file.          --//
//--                                                                           --//
//--                                                                           --//
//--                                                                           --//
//-- TODO: add catch_type to equilibrium calculations for reference points     --//
//--                                                                           --//
//-- Feb 18, 2013 - Need to redesign the simulation selectivities.             --//
//--              - Should probably use a separate simulation control file.    --//
//--                                                                           --//
//-- April 16, - Created new IPHC branch for developing sex/area/group         --//
//--           - INDEXS:                                                       --//
//--             area     f                                                    --//
//--             group    g                                                    --//
//--             sex      h                                                    --//
//--             year     i                                                    --//
//--             age      j                                                    --//
//--             gear     k                                                    --//
//--                                                                           --//
//--  ToDo: add mirror selectivity option so one fishery can assume the same   --//
//--        Selectivity value as another fishery with informative data.        --//
//--                                                                           --//
//--                                                                           --//
//--                                                                           --//
//--                                                                           --//
// ----------------------------------------------------------------------------- //



DATA_SECTION
	// |---------------------------------------------------------------------------------|
	// | STRINGS FOR INPUT FILES                                                         |
	// |---------------------------------------------------------------------------------|
	/// | DataFile.dat           : data to condition the assessment model on     
	init_adstring DataFile;      ///< String for the input datafile name.
	/// | ControlFile.ctl        : controls for phases, selectivity options 
	init_adstring ControlFile;	 ///< String for the control file.
	/// | ProjectFileControl.pfc : used for stock projections under TAC
	init_adstring ProjectFileControl;  ///< String for the projection file.

	init_adstring ProcedureControlFile;

	init_adstring ScenarioControlFile;
	/// | BaseFileName           : file prefix used for all iSCAM model output
	!! BaseFileName = stripExtension(ControlFile);  ///< BaseName given by the control file
	/// | ReportFileName         : file name to copy report file to.
	!! ReportFileName = BaseFileName + adstring(".rep");
	
	
	
	// |---------------------------------------------------------------------------------|
	// | READ IN PROJECTION FILE CONTROLS                                         
	// |---------------------------------------------------------------------------------|
	// | n_tac    : length of catch vector for decision table catch stream.
	// | tac      : vector of total catch values to be used in the decision table.
	// | pf_cntrl : vector of controls for the projections.
	// | Documentation for projection control file pf_cntrl
	// | 1) start year for m_bar calculation
	// | 2)   end year for m_bar calculation
	// | 3) start year for average fecundity/weight-at-age
	// | 4)   end year for average fecundity/weight-at-age
	// | 5) start year for recruitment period (not implemented yet)
	// | 6)   end year for recruitment period (not implemented yet)
	// |
	!! ad_comm::change_datafile_name(ProjectFileControl);
	/// | Number of catch options to explore in the decision table.
	init_int n_tac; ///< Number of catch options to explore in the decision table.
	// !! COUT(ProjectFileControl);
	// !! COUT(n_tac);
	/// | Vector of catch options.
	init_vector tac(1,n_tac);
	init_int n_pfcntrl;
	init_vector pf_cntrl(1,n_pfcntrl);

	//init_vector mse_cntrl(1,1);

	init_int eof_pf;
	LOC_CALCS
		if(eof_pf!=-999)
		{
			cout<<"Error reading projection file."<<endl;
			cout<<"Last integer read is "<<eof_pf<<endl;
			cout<<"The file should end with -999.\n Aborting!"<<endl;
			ad_exit(1);
		}
	END_CALCS
	
	
	// |---------------------------------------------------------------------------------|
	// | COMMAND LINE ARGUMENTS FOR SIMULATION & RETROSPECTIVE ANALYSIS
	// |---------------------------------------------------------------------------------|
	// | SimFlag    : if user specifies -sim, then turn SimFlag on.
	// | retro_yrs  : number of terminal years to remove.
	
	int SimFlag;  ///< Flag for simulation mode
	int mseFlag;  ///< Flag for management strategy evaluation mode
	int rseed;    ///< Random number seed for simulated data.
	int retro_yrs;///< Number of years to look back from terminal year.
	int NewFiles;
	int testMSY;
	LOC_CALCS
		SimFlag=0;
		rseed=999;
		int on,opt;
		//the following line checks for the "-SimFlag" command line option
		//if it exists the if statement retrieves the random number seed
		//that is required for the simulation model
		if((on=option_match(ad_comm::argc,ad_comm::argv,"-sim",opt))>-1)
		{
			SimFlag = 1;
			rseed   = atoi(ad_comm::argv[on+1]);
		}
		
		// Catarina implementing a new command for generating new data control and pfc file
		// for a new project.
		NewFiles = 0;
		if((on=option_match(ad_comm::argc,ad_comm::argv,"-new",opt))>-1)
		{
			NewFiles = 1;
			NewFileName = ad_comm::argv[on+1];
		}


		// command line option for retrospective analysis. "-retro retro_yrs"
		retro_yrs=0;
		if((on=option_match(ad_comm::argc,ad_comm::argv,"-retro",opt))>-1)
		{
			retro_yrs = atoi(ad_comm::argv[on+1]);
			cout<<"|—————————————————————————————————————————————————|\n";
			cout<<"| Implementing Retrospective analysis             |\n";
			cout<<"|—————————————————————————————————————————————————|\n";
			cout<<"| Number of retrospective years = "<<retro_yrs<<endl;
		}

		// Management strategy evaluation.
		mseFlag = 0;
		if((on=option_match(ad_comm::argc,ad_comm::argv,"-mse",opt))>-1)
		{
			mseFlag = 1;
			rseed   = atoi(ad_comm::argv[on+1]);
			cout<<"|—————————————————————————————————————————————————|\n";
			cout<<"|Implementing Management Strategy Evaluation      |\n";
			cout<<"|—————————————————————————————————————————————————|\n";
		}

		// Test MSY
		testMSY = 0;
		if((on=option_match(ad_comm::argc,ad_comm::argv,"-msy",opt))>-1)
		{
			cout<<"Testing MSY calculations with Spreadsheet MSF.xlsx"<<endl;
			testMSY = 1;
			
		}

	END_CALCS


	// |---------------------------------------------------------------------------------|
	// | MODEL DATA FROM DATA FILE
	// |---------------------------------------------------------------------------------|
	// |
	!! ad_comm::change_datafile_name(DataFile);

	// |---------------------------------------------------------------------------------|
	// | MODEL DIMENSIONS
	// |---------------------------------------------------------------------------------|
	// |
	// | area   f
	// | group  g
	// | sex    h
	// | year   i
	// | age    j
	// | gear   k  - number of gears with unique selectivity
	int f;
	int g; 
	int h;
	int i;
	int j;
	int k;

	init_int narea;			
	init_int ngroup;			
	init_int nsex;			
	init_int syr;			
	init_int nyr;				
	init_int sage;			
	init_int nage;			
	init_int ngear;				
	vector age(sage,nage);			



	// |---------------------------------------------------------------------------------|
	// | LINKS TO MANAGE ARRAY INDEXING
	// |---------------------------------------------------------------------------------|
	// | - n_ags: total number of areas * groups * sex
	// | - n_ag:  total number of areas * groups
	// | - n_gs:  total number of groups * sex
	// | - n_area:  vector of indexes for area for each sex & group combination.
	// | - n_group: vector of indexes for stock for each sex & area combination.
	// | - n_sex:   vector of indexes for sex foe each area & group combination.
	// | - pntr_ag: matrix of indices for area and group.
	// | - pntr_gs: matrix of indices for group and sex.
	// | - pntr_ags: d3_array of indices for area group sex.
	// |	
	int n_ags;
	!! n_ags = narea * ngroup * nsex;
	int n_ag;
	!! n_ag  = narea * ngroup;
	int n_gs;
	!! n_gs  = ngroup * nsex;
	ivector   n_area(1,n_ags);
	ivector  n_group(1,n_ags);
	ivector    n_sex(1,n_ags);
	imatrix  pntr_ag(1,narea,1,ngroup);
	imatrix  pntr_gs(1,ngroup,1,nsex);
	3darray pntr_ags(1,narea,1,ngroup,1,nsex);
	
	
	
	LOC_CALCS
		age.fill_seqadd(sage,1);
		int ig,ih,is;
		ig = 0;
		ih = 0;
		is = 0;
		for(f=1; f<=narea; f++)
		{
			for(g=1; g<=ngroup; g++)
			{
				ih ++;
				pntr_ag(f,g) = ih;
				for(h=1;h<=nsex;h++)
				{
					ig ++;
					n_area(ig)  = f;
					n_group(ig) = g;
					n_sex(ig)   = h;
					pntr_ags(f,g,h) = ig;
					if(f==1)
					{
						is ++;
						pntr_gs(g,h) = is;
					}
				}
			}
		}
		if(!mseFlag && verbose)
		{
		cout<<"| ----------------------- |"<<endl;
		cout<<"| MODEL DIMENSION         |"<<endl;
		cout<<"| ----------------------- |"<<endl;
		cout<<"| narea  \t"<<narea<<endl;
		cout<<"| ngroup \t"<<ngroup<<endl;
		cout<<"| nsex   \t"<<nsex<<endl;
		cout<<"| syr    \t"<<syr<<endl;
		cout<<"| nyr    \t"<<nyr<<endl;
		cout<<"| sage   \t"<<sage<<endl;
		cout<<"| nage   \t"<<nage<<endl;
		cout<<"| ngear  \t"<<ngear<<endl;
		cout<<"| n_area \t"<<n_area<<endl;
		cout<<"| n_group\t"<<n_group<<endl;
		cout<<"| n_sex  \t"<<n_sex<<endl;
		cout<<"| pntr_ag\n"<<pntr_ag<<endl;
		cout<<"| pntr_gs\n"<<pntr_gs<<endl;
		cout<<"| pntr_ags\n"<<pntr_ags(1)<<endl;
		cout<<"| ----------------------- |\n"<<endl;
		}
		
		/* Check for dimension errors in projection control file. */
		if( pf_cntrl(1)<syr || pf_cntrl(3)<syr || pf_cntrl(5)<syr )
		{
			cout<<"WARNING: start year in projection file control is" 
			" less than initial model year. Setting to syr."<<endl;
			// exit(1);
			pf_cntrl(1) = syr;
			pf_cntrl(3) = syr;
			pf_cntrl(5) = syr;
		}
		if( pf_cntrl(2)>nyr || pf_cntrl(4)>nyr || pf_cntrl(6)>nyr )
		{
			cout<<"ERROR: last year in projection file control is" 
			" greater than last model year."<<endl;
			exit(1);
		}
	END_CALCS
	
	
	// |---------------------------------------------------------------------------------|
	// | Allocation for each gear in (ngear), use 0 for survey gears.
	// |---------------------------------------------------------------------------------|
	// | fsh_flag is used to determine which fleets should be in MSY-based ref points
	// | If dAllocation >0 then set fish flag =1 else 0
	// | nfleet is the number of non-survey gear fleet with dAllocations > 0
	// |

	int nfleet;
	init_vector dAllocation(1,ngear);
	
	//init_ivector catch_sex_composition(1,ngear); 
	//init_ivector catch_type(1,ngear);

	ivector fsh_flag(1,ngear);


	LOC_CALCS
		dAllocation = dAllocation/sum(dAllocation);
		for(k=1;k<=ngear;k++)
		{
			if(dAllocation(k)>0)
				fsh_flag(k)=1;
			else
				fsh_flag(k)=0;
		}
		nfleet = sum(fsh_flag);
	END_CALCS

	vector  fleetAllocation(1,nfleet);
	ivector nFleetIndex(1,nfleet);



	LOC_CALCS

		fleetAllocation.initialize();
		j = 1;
		int jj = 1;
		for(k=1; k<=ngear;k++)
		{
			
			if(fsh_flag(k)){
				 nFleetIndex(j++) = k;
				 cout<<"nFleetIndex \t"<<nFleetIndex<<endl;
				 fleetAllocation(jj) = dAllocation(k);
				 jj++;
				}
			
		}
		 cout<<"nFleetIndex index\t"<<nFleetIndex<<endl;
		 cout<<"fleetAllocation \t"<<fleetAllocation<<endl;
		 //exit(1);
	END_CALCS
	
	
	// |---------------------------------------------------------------------------------|
	// | Growth and maturity parameters
	// |---------------------------------------------------------------------------------|
	// | n_ags -> number of areas * groups * sex
	// |

	init_vector  d_linf(1,n_ags);
	init_vector d_vonbk(1,n_ags);
	init_vector    d_to(1,n_ags);
	init_vector     d_a(1,n_ags);
	init_vector     d_b(1,n_ags);
	init_vector    d_ah(1,n_ags);
	init_vector    d_gh(1,n_ags);
	init_int 		n_MAT;
	int t1;
	int t2;
	LOC_CALCS
		if(n_MAT)
		{
			t1 = sage;
			t2 = nage;
		}
		else
		{
			t1 = 0;
			t2 = 0;
		}
	END_CALCS 
	
	init_vector 	d_maturityVector(t1,t2);

	// |----------------------|
	// | Aging error matrixes |
	// |----------------------|
	init_int n_age_err;
	init_3darray age_err(1,n_age_err,1,2,sage,nage);
	3darray age_age(1,n_age_err,sage,nage,sage,nage);
	LOC_CALCS
		for(int i = 1; i<=n_age_err; i++)
		{
			age_age(i) = ageErrorKey(age_err(i)(1),age_err(i)(2),age);
		}
	END_CALCS


	matrix la(1,n_ags,sage,nage);		//length-at-age
	matrix wa(1,n_ags,sage,nage);		//weight-at-age
	matrix ma(1,n_ags,sage,nage);		//maturity-at-age
	LOC_CALCS
		if(!mseFlag && verbose)
		{
		cout<<setw(8)<<setprecision(4)<<endl;
	    cout<<"| ----------------------- |"<<endl;
		cout<<"| GROWTH PARAMETERS       |"<<endl;
		cout<<"| ----------------------- |"<<endl;
		cout<<"| d_linf  \t"<<d_linf<<endl;
	  	cout<<"| d_vonbk \t"<<d_vonbk<<endl;
	  	cout<<"| d_to    \t"<<d_to<<endl;
	  	cout<<"| d_a     \t"<<d_a<<endl;
	  	cout<<"| d_b     \t"<<d_b<<endl;
	  	cout<<"| d_ah    \t"<<d_ah<<endl;
	  	cout<<"| d_gh    \t"<<d_gh<<endl;
	  	cout<<"| ----------------------- |\n"<<endl;
	  	}
	  	// length & weight-at-age based on input growth pars
	  	ma.initialize();
	  	for(ig=1;ig<=n_ags;ig++)
	  	{
	  		la(ig) = d_linf(ig)*(1. - exp(-d_vonbk(ig)*(age-d_to(ig))));
	  		wa(ig) = d_a(ig) * pow(la(ig),d_b(ig));
	  		h = n_sex(ig);
	  		if(n_MAT==0)
	  		{
	  			ma(ig) = plogis(age,d_ah(ig),d_gh(ig));
	  		}
	  		else if( n_MAT>0 && h !=2 )
	  		{
	  			ma(ig) = d_maturityVector;
	  		}
	  	}
	END_CALCS
	
	// |---------------------------------------------------------------------------------|
	// | Historical removal
	// |---------------------------------------------------------------------------------|
	// | - Total catch in weight (type=1), numbers (type=2), or roe (type=3).
	// | - dCatchData matrix cols: (year gear area group sex type value).
	// | - If total catch is asexual (sex=0), pool predicted catch from nsex groups.
	// | - ft_count  -> Number of estimated fishing mortality rate parameters.
	// | - d3_Ct     -> An array of observed catch in group(ig) year (row) by gear (col)
	// | - [?] - TODO: fix special case where nsex==2 and catch sex = 0 in catch array.
	init_int nCtNobs;
	init_matrix dCatchData(1,nCtNobs,1,8);
	3darray d3_Ct(1,n_ags,syr,nyr,1,ngear);

	int ft_count;
 	

	LOC_CALCS
		ft_count = nCtNobs;
		 cout<<"ma is "<<ma <<endl;
		 cout<<"nCtNobs is "<<nCtNobs <<endl;

		if(!mseFlag && verbose)
		{
		cout<<"| ----------------------- |"<<endl;
		cout<<"| ----------------------- |"<<endl;
		cout<<"| HEAD(dCatchData)        |"<<endl;
		cout<<"| ----------------------- |"<<endl;
		cout<<dCatchData.sub(1,3)<<endl;
		cout<<"| ----------------------- |\n"<<endl;
		cout<<"| ----------------------- |"<<endl;
		cout<<"| TAIL(dCatchData)        |"<<endl;
		cout<<"| ----------------------- |"<<endl;
		cout<<dCatchData.sub(nCtNobs-3,nCtNobs)<<endl;
		cout<<"| ----------------------- |\n"<<endl;
		}
		d3_Ct.initialize();
		
		for(int ii=1;ii<=nCtNobs;ii++)
		{
			i = dCatchData(ii)(1);
			k = dCatchData(ii)(2);
			f = dCatchData(ii)(3);
			g = dCatchData(ii)(4);
			h = dCatchData(ii)(5);
			if( h==0 )
			{
				for(h=1;h<=nsex;h++)
				{
					ig = pntr_ags(f,g,h);
					d3_Ct(ig)(i)(k) = 1./nsex*dCatchData(ii)(7);
				}
			}
			else
			{
				ig = pntr_ags(f,g,h);
				d3_Ct(ig)(i)(k) = dCatchData(ii)(7);
			} 
			//if(verbose)  cout<<"Ok after reading catch data"<<ii<<" "<<ig <<" "<<n_ags<<endl;
		}


		
	END_CALCS
	



	// |---------------------------------------------------------------------------------|
	// | RELATIVE ABUNDANCE INDICIES (ragged array)
	// |---------------------------------------------------------------------------------|
	// | nItNobs     = number of independent surveys
	// | n_it_nobs   = number of survey observations
	// | n_survey_type = 1: survey is proportional to vulnerable numbers
	// | n_survey_type = 2: survey is proportional to vulnerable biomass
	// | n_survey_type = 3: survey is proportional to vulnerable spawning biomass
	// | d3_survey_data: (iyr index(it) gear area group sex wt timing)
	// | DEPRECATED it_wt = relative weights for each relative abundance normalized to have a
	// | DEPRECATED mean = 1 so rho = sig^2/(sig^2+tau^2) holds true in variance pars.
	// |

	init_int nItNobs;
	ivector        nSurveyIndex(1,nItNobs);
	ivector          qdev_count(1,nItNobs);
	init_ivector      n_it_nobs(1,nItNobs);
	init_ivector  n_survey_type(1,nItNobs);
	init_3darray d3_survey_data(1,nItNobs,1,n_it_nobs,1,9);
	matrix                it_se(1,nItNobs,1,n_it_nobs);
	matrix            it_log_se(1,nItNobs,1,n_it_nobs);
	matrix            it_log_pe(1,nItNobs,1,n_it_nobs);
	matrix               it_grp(1,nItNobs,1,n_it_nobs);

// 	!! cout<<"Number of surveys "<<nItNobs<<endl;
	LOC_CALCS
		if(!mseFlag && verbose)
		{
		cout<<"| ----------------------- |"<<endl;
		cout<<"| TAIL(d3_survey_data)       |"<<endl;
		cout<<"| ----------------------- |"<<endl;
		cout<<d3_survey_data(nItNobs).sub(n_it_nobs(nItNobs)-3,n_it_nobs(nItNobs))<<endl;
		cout<<"| ----------------------- |\n"<<endl;
		}
		for(k=1;k<=nItNobs;k++)
		{
			//it_se(k) = column(d3_survey_data(k),7) + 1.e-30;
			it_log_se(k) = column(d3_survey_data(k),7);
			

			//I think this is a bug.
			//it_se(k) = 1.0/square(it_log_se(k));

			// and this is my fix
			it_se(k) = it_log_se(k);


			it_log_pe(k) = column(d3_survey_data(k),8);
			it_grp(k)= column(d3_survey_data(k),5);
			nSurveyIndex(k) = d3_survey_data(k)(1,3);
			qdev_count(k) = size_count(it_log_se(k));
		}
		// double tmp_mu = mean(it_se);
		// for(k=1;k<=nItNobs;k++)
		// {
		// 	it_se(k) = it_se(k)/tmp_mu;
		// }

	END_CALCS

	// |---------------------------------------------------------------------------------|
	// | AGE OR LENGTH COMPOSITION DATA (ragged object)
	// |---------------------------------------------------------------------------------|
	// | - nAgears    -> number of age-composition matrixes, one for each gear.
	// | - n_A_nobs   -> ivector for number of rows in age composition (A) matrix
	// | n_A_sage     -> imatrix for starting age in each row
	// | n_A_nage	  -> imatrix for plus group age in each row
	// | inp_nscaler  -> effective sample size for iterative re-weighting in multinomial.
	// | n_ageFlag 	  -> flag for age-comps or size-comps
	// | icol_A       -> number of columns for each row in A.
	// | A            -> array of data (year,gear,area,group,sex|Data...)
	// | d3_A_obs     -> array of catch-age data only.
	// |
	init_int nAgears;
	init_ivector n_A_nobs(1,nAgears);
	init_ivector n_A_sage(1,nAgears);
	init_ivector n_A_nage(1,nAgears);
	init_vector  inp_nscaler(1,nAgears);
	init_ivector n_ageFlag(1,nAgears);
  // The 5 in the next command is to remove the first 5 columns
  // from the age comp 'data' because they are not the actual ages,
  // but the header data.
	init_3darray d3_A(1,nAgears,1,n_A_nobs,n_A_sage-6,n_A_nage);
	3darray d3_A_obs(1,nAgears,1,n_A_nobs,n_A_sage,n_A_nage);
	LOC_CALCS


		if( n_A_nobs(nAgears) > 0 && n_A_nobs(nAgears) > 3)
		{
			if(!mseFlag  && verbose)
			{
			cout<<"| ----------------------- |"<<endl;
			cout<<"| TAIL(A)       |"<<endl;
			cout<<"| ----------------------- |"<<endl;
			cout<<setw(4)<<d3_A(nAgears).sub(n_A_nobs(nAgears)-2,n_A_nobs(nAgears))<<endl;
			cout<<"| ----------------------- |\n"<<endl;
			}
			for(k=1;k<=nAgears;k++)
			{
				dmatrix tmp = trans(trans(d3_A(k)).sub(n_A_sage(k),n_A_nage(k)));
				if(inp_nscaler(k) > 0)
				{
					for( i = 1; i <= n_A_nobs(k); i++ )
					{
						 tmp(i) = tmp(i)/sum(tmp(i)) * inp_nscaler(k);
					}
				}
				d3_A_obs(k) = tmp;
				//d3_A_obs(k) = trans(trans(d3_A(k)).sub(n_A_sage(k),n_A_nage(k)));
			}
		}
		else if(!mseFlag)
		{
			cout<<"| ----------------------- |"<<endl;
			cout<<"| NO AGE OR LENGTH DATA   |"<<endl;
			cout<<"| ----------------------- |"<<endl;
		}

	END_CALCS

	// |---------------------------------------------------------------------------------|
	// | EMPIRICAL WEIGHT_AT_AGE DATA
	// |---------------------------------------------------------------------------------|
	// | Mean weight-at-age data (kg) if nWtNobs > 0
	// | sage-5 = year
	// | sage-4 = gear
	// | sage-3 = area
	// | sage-2 = stock
	// | sage-1 = sex
	// | - construct and fill weight-at-age matrix for use in the model code  (d3_wt_avg)
	// | - construct and fill weight-at-age dev matrix for length-based selex (d3_wt_dev)
	// | - construct and fill fecundity-at-age matrix for ssb calculations.   (d3_wt_mat)
	// | [ ] - TODO fix h=0 option for weight-at-age data
	// | [ ] - TODO need to accomodate ragged arrays, or NA values, or partial d3_wt_avg.
	// | [ ] - TODO Construct AgeLength TM in data section for empirical weight-at-age.
	// | nWtTab  = number of Empirical weight-at-age tables.
	// | nWtNobs = number of rows in each weight-at-age table.
	// | d3_inp_wt_avg = input weight-at-age.

	init_int nWtTab;
	init_ivector nWtNobs(1,nWtTab);
	init_3darray d3_inp_wt_avg(1,nWtTab,1,nWtNobs,sage-5,nage);
	vector tmp_nWtNobs(1,nWtTab);
	int sum_tmp_nWtNobs; 
	vector projwt(1,nWtTab);
	vector n_bf_wt_row(1,nWtTab);



	LOC_CALCS		
		/*
		  This will determine the new dimension of d3_inp_wt_avg in case the backward 
		  projection is needed required and rename nWtNobs to tmp_nWtNobs 
		*/
		
		projwt.initialize();
		n_bf_wt_row.initialize();
		tmp_nWtNobs.initialize();

		for(int k=1; k<=nWtTab; k++)
		{
			tmp_nWtNobs(k) = nWtNobs(k);
			projwt(k)=1;

			for(i=1; i<=nWtNobs(k); i++)
			{
				if(nWtNobs(k) > 0 && d3_inp_wt_avg(k)(i)(sage-5) < 0)
				{
					n_bf_wt_row(k)++ ;

				}

			}	
			
			if(n_bf_wt_row(k)>0)
			{
				for(int i=1; i<=n_bf_wt_row(k); i++)
				{
					int exp_nyr = fabs(d3_inp_wt_avg(k,i,sage-5))-syr;
					tmp_nWtNobs(k) += exp_nyr; 
				}
				projwt(k)=-n_bf_wt_row(k);
			}	
				
			else if (n_bf_wt_row(k) == 0)
			{
				tmp_nWtNobs(k) = nWtNobs(k);
				projwt(k)=1;
			}
		}
		
		sum_tmp_nWtNobs = sum(tmp_nWtNobs);	
		
	END_CALCS

		3darray xinp_wt_avg(1,nWtTab,1,tmp_nWtNobs,sage-5,nage);
		matrix  xxinp_wt_avg(1,sum_tmp_nWtNobs,sage-5,nage);

	LOC_CALCS


		/*
		  This will redimension the d3_inp_wt_avg  according to tmp_nWtNobs and rename 
		  the 3d array to xinp_wt_avg. Then the 3darray is converted to a matrix 
		  xxinp_wt_avg
		*/

		xinp_wt_avg.initialize();
		xxinp_wt_avg.initialize();

  		for(int k=1; k<=nWtTab; k++)
		{
			ivector iroww(0,n_bf_wt_row(k));
			iroww.initialize();

			if(nWtNobs(k) > 0)
			{
				if(n_bf_wt_row(k) > 0)
				{
					for(i=1; i<=n_bf_wt_row(k); i++)
					{
						d3_inp_wt_avg(k,i,sage-5) = fabs(d3_inp_wt_avg(k,i,sage-5));
						iroww(i) = d3_inp_wt_avg(k,i,sage-5)-syr+iroww(i-1);

						for(int jj=iroww(i);jj>=iroww(i-1)+1;jj--)
	 					{
	 						xinp_wt_avg(k)(jj)(sage-5) = syr+jj-iroww(i-1)-1 ;
	 						xinp_wt_avg(k)(jj)(sage-4,nage) = d3_inp_wt_avg(k)(i)(sage-4,nage);

	 					}
					}
					
					for(int jj = iroww(n_bf_wt_row(k))+1; jj <= tmp_nWtNobs(k); jj++)
	 				{
	 					xinp_wt_avg(k)(jj)(sage-5,nage) = d3_inp_wt_avg(k)(jj-iroww(n_bf_wt_row(k)))(sage-5,nage);
	 				}	
				}
				else
	 			{
	 				for(int jj = 1; jj <= tmp_nWtNobs(k); jj++)
	 				{
	 					xinp_wt_avg(k)(jj)(sage-5,nage) = d3_inp_wt_avg(k)(jj)(sage-5,nage);
	 				}
	 			}
		
				int ttmp =	sum(tmp_nWtNobs(1,k-1));
				int ttmp2 =	sum(tmp_nWtNobs(1,k));

				for(int jj=ttmp+1; jj<=ttmp2; jj++) 
				{
					xxinp_wt_avg(jj)(sage-5,nage) = xinp_wt_avg(k)(jj-ttmp)(sage-5,nage);
				}
			}
		}


	END_CALCS

	matrix  dWt_bar(1,n_ags,sage,nage);
	3darray d3_wt_avg(1,n_ags,syr,nyr+1,sage,nage);
	3darray d3_wt_dev(1,n_ags,syr,nyr+1,sage,nage);
	3darray d3_wt_mat(1,n_ags,syr,nyr+1,sage,nage);
	3darray d3_len_age(1,n_ags,syr,nyr+1,sage,nage);

	// Trying to figure this out for Robyn forrest.
	// imatrix nrh(1,2,1,2);
	// imatrix nch(1,2,1,2);
	// !!nrh(1) = 1;
	// !!nrh(2) = 2;
	// !!nch(1) = 1;
	// !!nch(2) = 2;
	// !!COUT(nrh);
	// !!COUT(nch);
	// 4darray d4_alk(1,nAgears,1,n_A_nobs,sage,nrh,nage,nch);

	LOC_CALCS
		d3_wt_avg.initialize();
		d3_wt_dev.initialize();
		d3_wt_mat.initialize();
		d3_len_age.initialize();

		for(ig=1;ig<=n_ags;ig++)
		{
			for(int i = syr; i <= nyr; i++)
			{
				d3_wt_avg(ig)(i) = wa(ig);
				//d3_wt_mat(ig)(i) = pow(elem_prod(ma(ig),wa(ig)),d_iscamCntrl(6));
				d3_wt_mat(ig)(i) = elem_prod(ma(ig),wa(ig));
				d3_len_age(ig)(i) = pow(wa(ig)/d_a(ig),1./d_b(ig));

				// Insert calculations for ALK here.
			}
		}
		//cout<<"d3_wt_mat "<<d3_wt_mat<<endl;

		// the overwrite d3_wt_avg & d3_wt_mat with existing empirical data
		// SM Sept 6, 2013. Added option of using NA values (-99.0) for
		// missing weight-at-age data, or truncated age-data.
		int iyr;
		
		//if(nWtNobs(ii) > 0)
		//{
		for(i=1;i<=sum_tmp_nWtNobs;i++)
		{
			iyr = xxinp_wt_avg(i,sage-5);
			f   = xxinp_wt_avg(i,sage-3);
			g   = xxinp_wt_avg(i,sage-2);
			h   = xxinp_wt_avg(i,sage-1);

		// | SM Changed Sept 9, to accomodate NA's (-99) in empirical data.
			if( h )
			{
				ig                   = pntr_ags(f,g,h);
				dvector tmp          = xxinp_wt_avg(i)(sage,nage);
				ivector idx          = getIndex(age,tmp);
				for( int ii = 1; ii <= size_count(idx); ii++ )
				{
					d3_wt_avg(ig)(iyr)(idx(ii)) = xxinp_wt_avg(i)(idx(ii));
					d3_len_age(ig)(iyr)(idx(ii))= pow(d3_wt_avg(ig)(iyr)(idx(ii))
				                                  /d_a(ig),1./d_b(ig));
				 }
			//d3_wt_avg(ig)(iyr)(idx) = inp_wt_avg(i)(idx);
			d3_wt_mat(ig)(iyr)      = elem_prod(ma(ig),d3_wt_avg(ig)(iyr));
			//cout<<"Yep \t"<<inp_wt_avg(i)(idx)<<endl;
			//cout<<"Yep \t"<<tmp(idx)<<endl;
			//cout<<"Yep \t"<<d3_wt_avg(ig)(iyr)(idx)<<endl;
			}
			else if( !h ) 
			{
				for(int h=1;h<=nsex;h++)
				{
					ig                   = pntr_ags(f,g,h);
					dvector tmp          = xxinp_wt_avg(i)(sage,nage);
					ivector idx          = getIndex(age,tmp);
					// Problem, array indexed differ, must loop over idx;
					// d3_wt_avg(ig)(iyr)(idx) = inp_wt_avg(i)(idx);
					for( int ii = 1; ii <= size_count(idx); ii++)
					{
						d3_wt_avg(ig)(iyr)(idx(ii)) = xxinp_wt_avg(i)(idx(ii));
						d3_len_age(ig)(iyr)(idx(ii)) = pow(d3_wt_avg(ig)(iyr)(idx(ii))
					                               /d_a(ig),1./d_b(ig));
					}
					d3_wt_mat(ig)(iyr)      = elem_prod(ma(ig),d3_wt_avg(ig)(iyr));
				}
			}
		}


		//}
		

		// average weight-at-age in projection years
		for(ig=1;ig<=n_ags;ig++)
		{
			dWt_bar(ig)        = colsum(d3_wt_avg(ig).sub(pf_cntrl(3),pf_cntrl(4)));
			dWt_bar(ig)       /= pf_cntrl(4)-pf_cntrl(3)+1;
			d3_wt_avg(ig)(nyr+1) = dWt_bar(ig);
			d3_wt_mat(ig)(nyr+1) = elem_prod(dWt_bar(ig),ma(ig));
			d3_len_age(ig)(nyr+1) = pow(dWt_bar(ig)/d_a(ig),1./d_b(ig));
		}
		

		// deviations in mean weight-at-age
		for(ig=1;ig<=n_ags;ig++)
		{
			dmatrix mtmp = trans( d3_wt_avg(ig) );
			//COUT(mtmp);

			for(j=sage;j<=nage;j++)
			{
				//COUT(sum(first_difference(mtmp(j)(syr,nyr))));
				if( sum( first_difference(mtmp(j)(syr,nyr))) )
				{
					mtmp(j) = ( mtmp(j)-mean(mtmp(j)(syr,nyr)) ) 
							/ sqrt(var(mtmp(j)(syr,nyr)));
				}
				else
				{
					mtmp(j) = 0;
				}
			}
			d3_wt_dev(ig) = trans(mtmp);
			
			if( min(d3_wt_avg(ig))<=0.000 && min(d3_wt_avg(ig))!=NA )
			{
				cout<<"|-----------------------------------------------|"<<endl;
				cout<<"| ERROR IN INPUT DATA FILE FOR MEAN WEIGHT DATA |"<<endl;
				cout<<"|-----------------------------------------------|"<<endl;
				cout<<"| - Cannot have an observed mean weight-at-age  |"<<endl;
				cout<<"|   less than or equal to 0.  Please fix.       |"<<endl;
				cout<<"| - You are permitted to use '-99.0' for missing|"<<endl;
				cout<<"|   values in your weight-at-age data.          |"<<endl;
				cout<<"| - Aborting program!                           |"<<endl;
				cout<<"|-----------------------------------------------|"<<endl;
				ad_exit(1);
			}
		}
	END_CALCS
	
	
	// |---------------------------------------------------------------------------------|
	// | END OF DATA FILE
	// |---------------------------------------------------------------------------------|
	// |
	init_int eof;	
	LOC_CALCS
	  if(eof==999 ){
	  	if(verbose){
		cout<<"\n| -- END OF DATA SECTION -- |\n";
	  	cout<<"|         eof = "<<eof<<"         |"<<endl;
		cout<<"|___________________________|"<<endl;
		}
	  }else{
		cout<<"\n *** ERROR READING DATA *** \n"<<endl; 
		cout<<"|         eof = "<<eof<<"         |"<<endl;
		cout<<"|___________________________|"<<endl;
		exit(1);
	  }

	END_CALCS

	
	
	// |---------------------------------------------------------------------------------|
	// | VARIABLES FOR MSY-BASED REFERENCE POINTS
	// |---------------------------------------------------------------------------------|
	// |
	matrix fmsy(1,ngroup,1,nfleet);	//Fishing mortality rate at Fmsy
	matrix fall(1,ngroup,1,nfleet);	//Fishing mortality based on dAllocation
	matrix  msy(1,ngroup,1,nfleet);	//Maximum sustainable yield
	vector bmsy(1,ngroup);			//Spawning biomass at MSY
 // number Umsy;					//Exploitation rate at MSY
	vector age_tau2(1,nAgears);	//MLE estimate of the variance for age comps
 // 	//catch-age for simulation model (could be declared locally 3d_array)
 // 	3darray d3C(1,ngear,syr,nyr,sage,nage);		
	
	
		
	
	// |---------------------------------------------------------------------------------|
	// | CONTROL FILE
	// |---------------------------------------------------------------------------------|
	// |
	!! ad_comm::change_datafile_name(ControlFile);
	

	// |---------------------------------------------------------------------------------|
	// | Leading Parameters
	// |---------------------------------------------------------------------------------|
	// | npar            -> number of leading parameters
	// | ipar_vector     -> integer vector based on the number of areas groups sexes
	// | -1) log_ro      - unfished sage recruitment
	// | -2) steepness   - steepness of the stock-recruitment relationship
	// | -3) log_m       - instantaneous natural mortality rate
	// | -4) log_avgrec  - average sage recruitment from syr+1 to nyr
	// | -5) log_recinit - average sage recruitment for initialization
	// | -6) rho         - proportion of total variance for observation errors
	// | -7) vartheta    - total precision (1/variance)
	init_int npar;
	init_matrix theta_control(1,npar,1,7);
	
	vector   theta_ival(1,npar);
	vector     theta_lb(1,npar);
	vector     theta_ub(1,npar);
	ivector   theta_phz(1,npar);
	ivector theta_prior(1,npar);
	ivector ipar_vector(1,npar);
	LOC_CALCS
		theta_ival  = column(theta_control,1);
		theta_lb    = column(theta_control,2);
		theta_ub    = column(theta_control,3);
		theta_phz   = ivector(column(theta_control,4));
		theta_prior = ivector(column(theta_control,5));
		ipar_vector(1,2) = ngroup;
		ipar_vector(6,7) = ngroup;
		ipar_vector(3)   = n_gs;
		ipar_vector(4,5) = n_ag;

	END_CALCS
	
	// |---------------------------------------------------------------------------------|
	// | CONTROLS PARAMETERS FOR AGE/SIZE COMPOSITION DATA FOR na_gears                  |
	// |---------------------------------------------------------------------------------|
	// |
	
	init_ivector nCompIndex(1,nAgears);
	init_ivector nCompLikelihood(1,nAgears);
	init_vector  dMinP(1,nAgears);
	init_vector  dEps(1,nAgears);
	init_ivector nPhz_age_tau2(1,nAgears);
	init_ivector nPhz_phi1(1,nAgears);
	init_ivector nPhz_phi2(1,nAgears);
	init_ivector nPhz_df(1,nAgears);
	init_int check;
	LOC_CALCS
		if(check != -12345) 
		{
			COUT(check);cout<<"Error reading composition controls\n"<<endl; exit(1);
		}
	END_CALCS


	// |---------------------------------------------------------------------------------|
	// | CONTROLS FOR SELECTIVITY OPTIONS
	// |---------------------------------------------------------------------------------|
	// | - 12 different options for modelling selectivity which are summarized here:
	// | - isel_npar  -> ivector for # of parameters for each gear.
	// | - jsel_npar  -> ivector for the number of rows for time-varying selectivity.
	// | 
	// | SEL_TYPE  DESCRIPTION
	// |  1  -> age-based logistic function with 2 parameters.
	// |  2  -> age-based selectivity coefficients with nage-sage parameters.
	// |  3  -> cubic spline with age knots.
	// |  4  -> time-varying cubic spline with age knots.
	// |  5  -> time-varying bicubic spline with age and year knots.
	// |  6  -> logistic with fixed parameters.
	// |  7  -> logistic function of body weight with 2 parameters.
	// |  8  -> logistic 3 parameter function based on mean weight deviations.
	// |  11 -> length-based logistic function with 2 parametrs based on mean length.
	// |  12 -> length-based selectivity coefficients with cubic spline interpolation.
	// |	13 -> age-based selectivity coefficients with age_min-age_max parameters.
	// |
	// | selex_controls (1-10)
	// |  1  -> isel_type - switch for selectivity.
	// |  2  -> ahat (sel_type=1) - age-at-50% vulnerbality for logistic function or (sel_type=13) -age_min
	// |  3  -> ghat (sel_type=1) - std at 50% age of vulnerability for logistic function or (sel_type=13) -age_max
	// |  4  -> age_nodes - No. of age-nodes for bicubic spline.
	// |  5  -> yr_nodes  - No. of year-nodes for bicubic spline.
	// |  6  -> sel_phz   - phase for estimating selectivity parameters.
	// |  7  -> lambda_1  - penalty weight for 2nd difference in selectivity.
	// |  8  -> lambda_2  - penalty weight for dome-shaped selectivity.
	// |  9  -> lambda_3  - penalty weight for 2nd difference in time-varying selectivity.
	// |  10 -> Number of discrete selectivity blocks.
	// |


	/// April 13, issue 39.  Changing the way selectivity/retention is controlled.

!! #ifdef  NEW_SELEX
	init_imatrix slx_nBlocks(1,ngear,1,2);
	int slx_nrow;
	int ret_nrow
	!!  slx_nrow = sum(column(slx_nBlocks,1));
	!!  ret_nrow = sum(column(slx_nBlocks,2));
	init_matrix  slx_dControls(1,slx_nrow,1,13);
	init_matrix  ret_dControls(1,ret_nrow,1,13);

	ivector slx_nGearIndex(1,slx_nrow);   /// index for fishing gear.
	ivector      slx_nIpar(1,slx_nrow);   /// number of rows for each slx
	ivector      slx_nJpar(1,slx_nrow);   /// number of cols for each slx
	ivector   slx_nSelType(1,slx_nrow);   /// type of selectivity function
	ivector  slx_nAgeNodes(1,slx_nrow);   /// number of age/size nodes
	ivector   slx_nYrNodes(1,slx_nrow);   /// number of Year nodes
	ivector       slx_nSex(1,slx_nrow);   /// index for sex (0=both, 1=female, 2=male)
	ivector        slx_phz(1,slx_nrow);   /// phase of estimation or mirror index.
	ivector        slx_nsb(1,slx_nrow);   /// start of block year.
	ivector        slx_neb(1,slx_nrow);   /// end of block year.
	vector      slx_sel_mu(1,slx_nrow);
	vector      slx_sel_sd(1,slx_nrow);
	vector        slx_lam1(1,slx_nrow);
	vector        slx_lam2(1,slx_nrow);
	vector        slx_lam3(1,slx_nrow);


	LOC_CALCS
		slx_nGearIndex = ivector(column(slx_dControls,1));
		slx_nSelType   = ivector(column(slx_dControls,2));
		slx_nSex       = ivector(column(slx_dControls,5));
		slx_nAgeNodes  = ivector(column(slx_dControls,6));
		slx_nYrNodes   = ivector(column(slx_dControls,7));
		slx_phz        = ivector(column(slx_dControls,8));
		slx_nsb        = ivector(column(slx_dControls,12));
		slx_neb        = ivector(column(slx_dControls,13));
		slx_sel_mu     = column(slx_dControls,3);
		slx_sel_sd     = column(slx_dControls,4);
		slx_lam1       = column(slx_dControls,9);
		slx_lam2       = column(slx_dControls,10);
		slx_lam3       = column(slx_dControls,11);

		// • Count number of selectivity parameters required for each slx_type
		for(i = 1; i <= slx_nrow; i++)
		{
			slx_nIpar(i) = 1;

			switch(slx_nSelType(i))
			{
				// • logistic selectivity
				case 1:    
					slx_nJpar(i) = 2;
				break;

				// • age-specific coefficients
				case 2:
					slx_nJpar(i) = int(nage - sage);
				break;

				// • cubic spline over age/size
				case 3:
					slx_nJpar(i) = slx_nAgeNodes(i);
				break;

				// • cubic spline over age/size each year
				case 4:
					slx_nJpar(i) = slx_nAgeNodes(i);
					slx_nIpar(i) = slx_neb(i) - slx_nsb(i) + 1;
				break;

				// • bicubic spline over age-size / years
				case 5:
					slx_nIpar(i) = slx_nAgeNodes(i);
					slx_nJpar(i) = slx_nYrNodes(i);
				break;

				// • logistic based on weight-at-age deviations.
				case 6:
					slx_nJpar(i) = 2;
				break;

				// • logistic based on weight-at-age devs and scalar parameter.
				case 7:
					slx_nJpar(i) = 3;
				break;

				// • age-specific coefficients between lb_age <= age <= ub_age
				// case 8:

				// • logistic based on mean length-at-age.
				case 11:
					slx_nJpar(i) = 2;
				break;

				// • size-specific coefficients.
				//case 12:

				// • size-based cubic spline over mean size-at-age
				case 13:
					slx_nJpar(i) = slx_nAgeNodes(i);
				break;
			}
		} 
		// COUT(slx_nrow);
		// cout<<"Ok after new selex stuff in data section"<<endl;
		

	END_CALCS



!! #endif


	init_matrix selex_controls(1,10,1,ngear);
	

	ivector    isel_npar(1,ngear);	
	ivector    jsel_npar(1,ngear);	
	ivector    isel_type(1,ngear);	
	ivector      sel_phz(1,ngear);	
	ivector n_sel_blocks(1,ngear);	
	vector      ahat_agemin(1,ngear);	
	vector      ghat_agemax(1,ngear);
	vector age_nodes(1,ngear);	
	vector  yr_nodes(1,ngear);	
	vector  lambda_1(1,ngear);	
	vector  lambda_2(1,ngear);	
	vector  lambda_3(1,ngear);	
	
	LOC_CALCS
		ahat_agemin      = selex_controls(2);
		ghat_agemax      = selex_controls(3);
		age_nodes = selex_controls(4);
		yr_nodes  = selex_controls(5);
		lambda_1  = selex_controls(7);
		lambda_2  = selex_controls(8);
		lambda_3  = selex_controls(9);

		isel_type    = ivector(selex_controls(1));
		sel_phz      = ivector(selex_controls(6));
		n_sel_blocks = ivector(selex_controls(10));
	END_CALCS
	
	init_imatrix sel_blocks(1,ngear,1,n_sel_blocks);


	LOC_CALCS
		// | COUNT THE NUMBER OF ESTIMATED SELECTIVITY PARAMETERS TO ESTIMATE
		// | isel_npar number of columns for each gear.
		// | jsel_npar number of rows for each gear.
		isel_npar.initialize();
		for(i=1;i<=ngear;i++)
		{	
			jsel_npar(i)=1;
			switch(isel_type(i))
			{
				case 1:
					// logistic selectivity
					isel_npar(i) = 2;
					jsel_npar(i) = n_sel_blocks(i); 
					break;
					
				case 2:
					// age-specific coefficients
					isel_npar(i) = (nage-sage);
					jsel_npar(i) = n_sel_blocks(i);
					break;
					
				case 3:
				 	// cubic spline 
					isel_npar(i) = age_nodes(i);
					jsel_npar(i) = n_sel_blocks(i);
					break;
					
				case 4:	 
					// annual cubic splines
					isel_npar(i) = age_nodes(i);
					jsel_npar(i) = (nyr-syr-retro_yrs)+1;
					break;
					
				case 5:  
					// bicubic spline
					jsel_npar(i) = age_nodes(i);
					isel_npar(i) = yr_nodes(i);
					break;
				
				case 6:
					// fixed logistic (no parameters estimated)
					// ensure sel_phz is set to negative value.
					isel_npar(i) = 2;
					if(sel_phz(i)>0) sel_phz(i) = -1;
					break;
					
				case 7:
					// CHANGED: Now working, Vivian Haist fixed it.
					// logistic (3 parameters) with mean body 
					// weight deviations. 
					isel_npar(i) = 2;
					jsel_npar(i) = n_sel_blocks(i);
					break;
					
				case 8:
					// Alternative logistic selectivity with d3_wt_dev coefficients.
					isel_npar(i) = 3;
					jsel_npar(i) = n_sel_blocks(i);
					break;
					
				case 11:
					// Logistic length-based selectivity.
					isel_npar(i) = 2;
					jsel_npar(i) = n_sel_blocks(i);
					break;
					
				case 12:
					// Length-based selectivity coeffs with cubic spline interpolation
					isel_npar(i) = age_nodes(i);
					jsel_npar(i) = n_sel_blocks(i);
					break;

				case 13:
					// age-specific coefficients for agemin to agemax
					isel_npar(i) = (ghat_agemax(i)-ahat_agemin(i)+1);
					jsel_npar(i) = n_sel_blocks(i);

					
				default: break;
			}
		}


	END_CALCS
	
	// |--------------------------------------------------|
	// | OPTIONS FOR TIME-VARYING NATURAL MORTALITY RATES |
	// |--------------------------------------------------|
	// | nMdev    	-> number of deviation parameters in M
	// | m_type   	-> type of model (0=constant M, 1=random walk, 2=cubic spline)
	// | Mdev_phz 	-> Phase of estimation
	// | m_stdev		-> Standard deviation for constraint.
	// | m_nNodes		-> number of nodes for cubic spline.
	// | m_nodeyear -> position of the nodes.
	int 				nMdev;
	init_int 			m_type;
	init_int 			Mdev_phz;
	init_number 		m_stdev;
	init_int 			m_nNodes;
	init_ivector m_nodeyear(1,m_nNodes);

	
	// |---------------------------------------------------------------------------------|
	// | PRIOR FOR RELATIVE ABUNDANCE DATA
	// |---------------------------------------------------------------------------------|
	// | nits     -> number of relative abundance indices
	// | q_prior  -> type of prior to use, see legend
	// | mu_log_q -> mean q in log-space
	// | sd_log_q -> std of q prior in log-space
	// |
	// | q_prior type:
	// | 0 -> uninformative prior.
	// | 1 -> normal prior on q in log-space.
	// | 2 -> penalized random walk in q.
	init_int nits;					
	init_ivector q_prior(1,nits);
	init_vector mu_log_q(1,nits);
	init_vector sd_log_q(1,nits);
	init_ivector q_phz(1,nits);
	
	// |---------------------------------------------------------------------------------|
	// | Miscellaneous controls                                                          |
	// |---------------------------------------------------------------------------------|
	// | 1 -> verbose
	// | 2 -> recruitment model (1=beverton-holt, 2=rickers)
	// | 3 -> std in catch first phase
	// | 4 -> std in catch in last phase
	// | 5 -> assumed unfished in first year (0=FALSE, 1=TRUE)
	// | 6 -> Maternal effects power parameter (1=no maternal effects).
	// | 7 -> mean fishing mortality rate to regularize the solution
	// | 8 -> standard deviation of mean F penalty in first phases
	// | 9 -> standard deviation of mean F penalty in last phase.
	// | 10-> phase for estimating deviations in natural mortality.
	// | 11-> std in natural mortality deviations.
	// | 12-> number of estimated nodes for deviations in natural mortality
	// | 13-> fraction of total mortality that takes place prior to spawning
	// | 14-> number of prospective years to start estimation from syr.
	// | 15-> switch for generating selex based on IFD and cohort biomass
	init_vector d_iscamCntrl(1,15);
	int verbose;
	

	init_int eofc;
	LOC_CALCS
		verbose = d_iscamCntrl(1);
		if(verbose) COUT(d_iscamCntrl);
		
		// WTF is this??? d_iscamCntrl(6))i s the minimum proportion to be considered in dmvlogistic.
		//makes no sense to CW so I'm commenting it out
		//for(int ig=1;ig<=n_ags;ig++)
		//{
		//	for(int i = syr; i <= nyr; i++)
		//	{
		//		d3_wt_mat(ig)(i) = pow(d3_wt_mat(ig)(i),d_iscamCntrl(6));
		//	}
		//}

		//cout<<"d3_wt_mat "<<d3_wt_mat<<endl;
		//exit(1);
		



		if(eofc==999){
			if(verbose){
			cout<<"\n| -- END OF CONTROL SECTION -- |\n";
		  	cout<<"|          eofc = "<<eofc<<"          |"<<endl;
			cout<<"|______________________________|"<<endl;
			}
		}else{
			cout<<"\n ***** ERROR CONTROL FILE ***** \n"<<endl; 
			cout<<"|          eofc = "<<eofc<<"          |"<<endl;
			exit(1);
		}
	END_CALCS
	
	int nf;
	
	// |---------------------------------------------------------------------------------|
	// | VECTOR DIMENSIONS FOR NEGATIVE LOG LIKELIHOODS
	// |---------------------------------------------------------------------------------|
	// | ilvec[1,5,6,7] -> number of fishing gears (ngear)
	// | ilvec[2]       -> number of surveys       (nItNobs)
	// | ilvec[3]       -> number of age-compisition data sets (nAgears)
	// | ilvec[4]       -> container for recruitment deviations.
	ivector ilvec(1,8);
	!! ilvec    = ngear;
	!! ilvec(1) = 1;			
	!! ilvec(2) = nItNobs;			
	!! ilvec(3) = nItNobs;			
	!! ilvec(4) = nAgears;		
	!! ilvec(5) = ngroup;
	

	// |---------------------------------------------------------------------------------|
	// | RETROSPECTIVE ADJUSTMENT TO nyrs
	// |---------------------------------------------------------------------------------|
	// | - Don't read any more input data from here on in. 
	// | - Modifying nyr to allow for retrospective analysis.
	// | - If retro_yrs > 0, then ensure that pf_cntrl arrays are not greater than nyr,
	// |   otherwise arrays for mbar will go out of bounds.
	// | - Reduce ft_count so as not to bias estimates of ft.
	// | - Establish retrospective counter for Composition data n_naa;

	ivector n_naa(1,nAgears);

	!! nyr = nyr - retro_yrs;
	LOC_CALCS

		if(retro_yrs)
		{
			if(pf_cntrl(2)>nyr) pf_cntrl(2) = nyr;
			if(pf_cntrl(4)>nyr) pf_cntrl(4) = nyr;
			if(pf_cntrl(6)>nyr) pf_cntrl(6) = nyr;
		}
		for( i = 1; i <= nCtNobs; i++ )
		{
			if( dCatchData(i)(1) > nyr ) ft_count --;
		}

		for( k = 1; k <= nItNobs; k++ )
		{
			for( i = 1; i <= n_it_nobs(k); i++ )
			{
				if( d3_survey_data(k)(i)(1) > nyr) qdev_count(k) --;
			}
		}

		// Retrospective counter for n_A_nobs
		n_naa.initialize();
		for( k = 1; k <= nAgears; k++ )
		{
			for( i = 1; i <= n_A_nobs(k); i++ )
			{
				int iyr = d3_A(k)(i)(n_A_sage(k)-6);	//index for year
				if( iyr <= nyr ) n_naa(k)++;
			}
		}

	END_CALCS

	// |---------------------------------------------------------------------------------|
	// | PROSPECTIVE ADJUSTMENT TO syr                                                   |
	// |---------------------------------------------------------------------------------|
	// | - start assessment at syr + # of prospective years.
	// | - adjust sel_blocks to new syr
	// | - Reduce ft_count so as not to bias estimates of ft.
	// | - Establish prospective counter for Composition data   n_saa;
	// | - Reduce qdev_count

	ivector n_saa(1,nAgears);

	!! syr = syr + (int)d_iscamCntrl(14);
	LOC_CALCS

		//sel_blocks(1,ngear,1,n_sel_blocks);
		for(int k = 1; k <= ngear; k++ )
		{
			sel_blocks(k)(1) = syr;
		}
		if(pf_cntrl(1)<syr) pf_cntrl(1) = syr;
		if(pf_cntrl(3)<syr) pf_cntrl(3) = syr;
		if(pf_cntrl(5)<syr) pf_cntrl(5) = syr;


		for( i = 1; i <= nCtNobs; i++ )
		{
			if( dCatchData(i)(1) < syr ) ft_count --;
		}
		// Prospective counter for n_A_nobs
		n_saa.initialize();
		n_saa = 1;
		for( k = 1; k <= nAgears; k++ )
		{
			for( i = 1; i <= n_A_nobs(k); i++ )
			{
				int iyr = d3_A(k)(i)(n_A_sage(k)-6);	//index for year
				if( iyr < syr ) n_saa(k)++;
			}
		}
		

		for( k = 1; k <= nItNobs; k++ )
		{
			for( i = 1; i <= n_it_nobs(k); i++ )
			{
				if( d3_survey_data(k)(i)(1) < syr) qdev_count(k) --;
			}
		}
	END_CALCS

	LOC_CALCS
		// Determine number of parameters for natural mortality rate.
		switch( m_type )
		{
			case 0:
				nMdev = 0; 
				Mdev_phz = -1;
			break;
			case 1: 
				nMdev = nyr-syr; 
			break;
			case 2:
				nMdev = m_nNodes;
				// ensure m_nodeyear > syr and < nyr
				for( i = 1; i <= m_nNodes; i++ )
				{
					if(m_nodeyear(i) < syr) m_nodeyear(i) = syr;
					if(m_nodeyear(i) > nyr) m_nodeyear(i) = nyr;
				}
			break;
		}


	END_CALCS

	// !! COUT((n_saa));
	// !! COUT((n_naa));


	// |---------------------------------------------------------------------------------|
	// | MANAGEMENT STRATEGY EVALUATION INPUTS
	// |---------------------------------------------------------------------------------|
	// |



	// |--------------------------------------|
	// | Friend Class Operating Model for MSE |
	// |--------------------------------------|
	friend_class OperatingModel;
	
	// END OF DATA_SECTION
	!! if(verbose) cout<<"||-- END OF DATA_SECTION --||"<<endl;

INITIALIZATION_SECTION
  theta theta_ival;
  phi1 0.0;
	
PARAMETER_SECTION
	
	// |---------------------------------------------------------------------------------|
	// | LEADING PARAMTERS
	// |---------------------------------------------------------------------------------|
	// | - Initialized in the INITIALIZATION_SECTION with theta_ival from control file.
	// | [ ] Change to init_bounded_vector_vector.
	// | theta[1] -> log_ro, or log_msy
	// | theta[2] -> steepness(h), or log_fmsy
	// | theta[3] -> log_m
	// | theta[4] -> log_avgrec
	// | theta[5] -> log_recinit
	// | theta[6] -> rho
	// | theta[7] -> vartheta
	// |
	init_bounded_vector_vector theta(1,npar,1,ipar_vector,theta_lb,theta_ub,theta_phz);

	
	// |---------------------------------------------------------------------------------|
	// | SELECTIVITY PARAMETERS
	// |---------------------------------------------------------------------------------|
	// | - This is a bounded matrix vector where the dimensions are defined by the 
	// | - selectivity options specified in the control file.
	// | - There are 1:ngear arrays, having jsel_npar rows and isel_npar columns.
	// | - If the user has not specified -ainp or -binp, the initial values are set
	// |   based on ahat and ghat in the control file for logistic selectivities.
	// | - Special case: if SimFlag=TRUE, then add some random noise to ahat.
	// | - NB  sel_par is in log space.
	// |
!! #ifdef NEW_SELEX
	init_bounded_matrix_vector slx_log_par(1,slx_nrow,1,slx_nIpar,1,slx_nJpar,-25.0,25.0,slx_phz);
	// TO DO set initial values for slx parameters.
	LOC_CALCS
		if( !global_parfile )
		{
			for(int k = 1; k <= slx_nrow; k++ )
			{
				if(slx_nSelType(k)==1)
				{
					for(int j = 1; j <= slx_nIpar(k); j++ )
					{
						// cout<<"Made it here"<<endl;
						slx_log_par(k)(j)(1) = log(slx_sel_mu(k));
						slx_log_par(k)(j)(2) = log(slx_sel_sd(k));
						// cout<<"and here too"<<endl;
					}
				}
			}
		}
	END_CALCS

!! #endif

	init_bounded_matrix_vector sel_par(1,ngear,1,jsel_npar,1,isel_npar,-25.,25.,sel_phz);

	LOC_CALCS
		if ( !global_parfile )
		{
			for(int k=1; k<=ngear; k++)
			{
				if( isel_type(k)==1 || 
					isel_type(k)==6 || 
					(
					isel_type(k)>=7 && 
					isel_type(k) <= 12 
					)
					)
				{
					for(int j = 1; j <= n_sel_blocks(k); j++ )
					{
						double uu = 0;
						if(SimFlag && j > 1)
						{
							uu = 0.05*randn(j+rseed);
						} 
						sel_par(k,j,1) = log(ahat_agemin(k)*exp(uu));
						sel_par(k,j,2) = log(ghat_agemax(k));
					}
				}
				else if( isel_type(k) ==13 )
				{
					for(int j = 1; j <= n_sel_blocks(k); j++ )
					{
						double dd = 1.e-8;
						double stp = 1.0/(ghat_agemax(k)-ahat_agemin(k));
						sel_par(k)(j).fill_seqadd(dd,stp);

						//COUT(sel_par(k)(j));
						//exit(1);
					}
				}
			}
		}

	END_CALCS
	

	// |---------------------------------------------------------------------------------|
	// | FISHING MORTALITY RATE PARAMETERS
	// |---------------------------------------------------------------------------------|
	// | - Estimate all fishing mortality rates in log-space.
	// | - If in simulation mode then initialize with F=0.1; Actual F is conditioned on 
	// |   the observed catch.
	// |
	init_bounded_vector log_ft_pars(1,ft_count,-30.,3.0,1);
	LOC_CALCS
		if(!SimFlag && !global_parfile) log_ft_pars = log(0.10);
	END_CALCS
	
	

	// |---------------------------------------------------------------------------------|
	// | INITIAL AND ANNUAL RECRUITMENT 
	// |---------------------------------------------------------------------------------|
	// | - Estimate single mean initial recruitment and deviations for each initial 
	// |   cohort from sage+1 to nage. (Rinit + init_log_rec_devs)
	// | - Estimate mean overal recruitment and annual deviations from syr to nyr.
	// | - d_iscamCntrl(5) is a flag to initialize the model at unfished recruitment (ro),
	// |   if this is true, then do not estimate init_log_rec_devs
	// | [ ] - TODO add dev contstraint for rec_devs in calc_objective_function.

	!! int init_dev_phz = 2;
	!! if(d_iscamCntrl(5)) init_dev_phz = -1;
	init_bounded_matrix init_log_rec_devs(1,n_ag,sage+1,nage,-15.,15.,init_dev_phz);
	init_bounded_matrix log_rec_devs(1,n_ag,syr,nyr,-15.,15.,2);
	// !! COUT(log_rec_devs);
	// !! exit(1);


	// |---------------------------------------------------------------------------------|
	// | DEVIATIONS FOR NATURAL MORTALITY BASED ON CUBIC SPLINE INTERPOLATION
	// |---------------------------------------------------------------------------------|
	// | - Estimating trends in natural mortality rates, where the user specified the 
	// |   number of knots (d_iscamCntrl(12)) and the std in M in the control file, and the phase
	// |   in which to estimate natural mortality devs (d_iscamCntrl(10)).  If the phase is neg.
	// |   then natural mortality rate deviates are not estimated and M is assumed const.
	// | - This model is implemented as a random walk, where M{t+1} = M{t} + dev.
	
	//!! int m_dev_phz = -1;
	//!!     m_dev_phz = d_iscamCntrl(10);
	//!! int  n_m_devs = d_iscamCntrl(12);
	//init_bounded_vector log_m_nodes(1,n_m_devs,-5.0,5.0,m_dev_phz);
	init_bounded_vector log_m_nodes(1,nMdev,-5.0,5.0,Mdev_phz);

	// |---------------------------------------------------------------------------------|
	// | DEVIATIONS IN CATCHABILITY COEFFICIENTS ASSUMING A RANDOM WALK                  |
	// |---------------------------------------------------------------------------------|
	// | 
	//init_bounded_vector_vector log_q_devs(1,nItNobs,1,n_it_nobs,-5.0,5.0,q_phz);
	// !! COUT(n_it_nobs);
	// !! COUT(qdev_count);
	//!! exit(1);
	init_bounded_vector_vector log_q_devs(1,nItNobs,1,qdev_count,-5.0,5.0,q_phz);


	// |---------------------------------------------------------------------------------|
	// | CORRELATION COEFFICIENTS FOR AGE COMPOSITION DATA USED IN LOGISTIC NORMAL       |
	// |---------------------------------------------------------------------------------|
	// | log_age_tau2 is the variance of the composition errors.
	// | phi1 is the AR1 coefficient
	// | phi2 used in AR2 process.
	init_bounded_number_vector log_age_tau2(1,nAgears,-4.65,5.30,nPhz_age_tau2);
	init_bounded_number_vector phi1(1,nAgears,-1.0,1.0,nPhz_phi1);
	init_bounded_number_vector phi2(1,nAgears,0.0,1.0,nPhz_phi2);
	init_bounded_number_vector log_degrees_of_freedom(1,nAgears,-10.0,10.0,nPhz_df);

	// |---------------------------------------------------------------------------------|
	// | DEPRECATE AUTOCORRELATION IN RECRUITMENT DEVIATIONS                                       |
	// |---------------------------------------------------------------------------------|
	// | gamma_r: what fraction of the residual from year t-2 carries over to t-1.
	//init_bounded_number gamma_r(0,1,-4);
	//!!gamma_r = 0;

	// |---------------------------------------------------------------------------------|
	// | OBJECTIVE FUNCTION VALUE
	// |---------------------------------------------------------------------------------|
	// | - the value that ADMB will minimize, called objfun in iSCAM
	// |
	objective_function_value objfun;

    // |---------------------------------------------------------------------------------|
    // | POPULATION VARIABLES
    // |---------------------------------------------------------------------------------|
    // | - m_bar       -> Average natural mortality rate from syr to nyr.
    // |
	number m_bar;	///< Average natural mortality rate.			
	number phib;//,so,beta;
	

	// |---------------------------------------------------------------------------------|
	// | POPULATION VECTORS
	// |---------------------------------------------------------------------------------|
    // | - ro          -> theoretical unfished age-sage recruits. 
    // | - bo          -> theoretical unfished spawning biomass (MSY-based ref point).
    // | - sbo         -> unfished spawning biomass at the time of spawning.
    // | - kappa       -> Goodyear recruitment compensation ratio K = 4h/(1-h); h=K/(4+K)
    // | - so          -> Initial slope (max R/S) of the stock-recruitment relationship.
    // | - beta        -> Density dependent term in the stock-recruitment relationship.
    // | - m           -> Instantaneous natural mortality rate by nsex
    // | - log_avgrec  -> Average sage recruitment(syr-nyr,area,group).
    // | - log_recinit -> Avg. initial recruitment for initial year cohorts(area,group).
	// | - log_m_devs  -> annual deviations in natural mortality.
	// | - q           -> conditional MLE estimates of q in It=q*Bt*exp(epsilon)
	// | - ct          -> predicted catch for each catch observation
	// | - eta         -> standardized log residual (log(obs_ct)-log(ct))/sigma_{ct}
    // | - rho         -> Proportion of total variance associated with obs error.
    // | - varphi      -> Total precision of CPUE and Recruitment deviations.
    // | - sig         -> DEPRCATE. STD of the observation errors in relative abundance data.
    // | - tau         -> STD of the process errors (recruitment deviations).
	// | - phiE 	   -> per recruit yield at unfished equilibrium -- analogous to phib but group-specific
 	// | - phie 	   -> per recruit yield at fished conditions -- 
	// | - spr 		   -> SPR ratio
	// | - fspr 	   -> avetage (over gears) F that will lead to SPR target
	// |

	vector        ro(1,ngroup);
	vector        bo(1,ngroup);
	vector       sbo(1,ngroup);
	vector     kappa(1,ngroup);
	vector steepness(1,ngroup);
	vector        so(1,ngroup);
	vector      beta(1,ngroup);
	vector           m(1,n_gs);	
	vector  log_avgrec(1,n_ag);			
	vector log_recinit(1,n_ag);			
	vector          q(1,nItNobs);
	vector         ct(1,nCtNobs);
	vector        eta(1,nCtNobs);	
	vector log_m_devs(syr+1,nyr);
	vector     rho(1,ngroup);	
	vector  varphi(1,ngroup);
	vector     sig(1,ngroup);	
	vector     tau(1,ngroup);
  	vector sigma_r(1,ngroup); 
  	vector phie(1,ngroup);
	vector phiE(1,ngroup);
	vector spr(1,ngroup);

	//matrix allspr(1,ngroup,1,4001); 
	//matrix diffspr(1,ngroup,1,4001);
	matrix fspr(1,ngroup,1,nfleet);
	
	// |---------------------------------------------------------------------------------|
	// | MATRIX OBJECTS
	// |---------------------------------------------------------------------------------|
	// | - log_rt   -> age-sage recruitment for initial years and annual recruitment.
	// | - catch_df -> Catch data_frame (year,gear,area,group,sex,type,obs,pred,resid)
	// | - eta      -> log residuals between observed and predicted total catch.
	// | - nlvec    -> matrix for negative loglikelihoods.
	// | - epsilon  -> residuals for survey abundance index observation errors.
	// | - xi       -> residual process errors for changes in catchability.
	// | - it_hat   -> predicted survey index (no need to be differentiable)
	// | - qt       -> catchability coefficients (time-varying)
	// | - sbt      -> spawning stock biomass by group used in S-R relationship.
	// | - bt       -> average biomass by group used for stock projection
	// | - rt          -> predicted sage-recruits based on S-R relationship.
	// | - delta       -> residuals between estimated R and R from S-R curve (process err)
	// | 
	matrix  log_rt(1,n_ag,syr-nage+sage,nyr);
	matrix   nlvec(1,8,1,ilvec);	
	matrix epsilon(1,nItNobs,1,n_it_nobs);
	matrix      xi(1,nItNobs,1,n_it_nobs);
	matrix  it_hat(1,nItNobs,1,n_it_nobs);
	matrix      qt(1,nItNobs,1,n_it_nobs);
	matrix     sbt(1,ngroup,syr,nyr+1);
	matrix      bt(1,ngroup,syr,nyr+1);
	matrix      rt(1,ngroup,syr+sage,nyr); 
	matrix   delta(1,ngroup,syr+sage,nyr);

	
	// |---------------------------------------------------------------------------------|
	// | THREE DIMENSIONAL ARRAYS
	// |---------------------------------------------------------------------------------|
	// | - ft       -> Mean fishing mortality rates for (area-sex, gear, year)
	// | F          -> Instantaneous fishing mortality rate for (group,year,age)
	// | M          -> Instantaneous natural mortality rate for (group,year,age)
	// | Z          -> Instantaneous total  mortalityr rate Z=M+F for (group,year,age)
	// | S          -> Annual survival rate exp(-Z) for (group,year,age)
	// | N          -> Numbers-at-age for (group,year+1,age)
	// | - A_hat    -> ragged matrix for predicted age-composition data.
	// | - A_nu		-> ragged matrix for age-composition residuals.
	// | 
	// |
	3darray  ft(1,n_ags,1,ngear,syr,nyr);
	3darray   F(1,n_ags,syr,nyr,sage,nage);
	3darray   M(1,n_ags,syr,nyr,sage,nage);
	3darray   Z(1,n_ags,syr,nyr,sage,nage);
	3darray   S(1,n_ags,syr,nyr,sage,nage);
	3darray   N(1,n_ags,syr,nyr+1,sage,nage);
	3darray  A_hat(1,nAgears,1,n_A_nobs,n_A_sage,n_A_nage);
	3darray   A_nu(1,nAgears,1,n_A_nobs,n_A_sage,n_A_nage);
	
	// //matrix jlog_sel(1,ngear,sage,nage);		//selectivity coefficients for each gear type.
	// //matrix log_sur_sel(syr,nyr,sage,nage);	//selectivity coefficients for survey.
	 
	// matrix Z(syr,nyr,sage,nage);
	// matrix S(syr,nyr,sage,nage);
	// matrix pit(1,nItNobs,1,n_it_nobs);			//predicted relative abundance index
	

	// 3darray Ahat(1,nAgears,1,n_A_nobs,n_A_sage-2,n_A_nage);		//predicted age proportions by gear & year
	// 3darray A_nu(1,nAgears,1,n_A_nobs,n_A_sage-2,n_A_nage);		//residuals for age proportions by gear & year
	
	// |---------------------------------------------------------------------------------|
	// | FOUR DIMENSIONAL ARRAYS
	// |---------------------------------------------------------------------------------|
	// | log_sel    -> Selectivity for (gear, group, year, age)
	// | Chat       -> Predicted catch-age array for (gear, group, year, age)
	// | 
	4darray log_sel(1,ngear,1,n_ags,syr,nyr,sage,nage);
	// 4darray    Chat(1,ngear,1,n_ags,syr,nyr,sage,nage);		
	

	// |---------------------------------------------------------------------------------|
	// | SDREPORT VARIABLES AND VECTORS
	// |---------------------------------------------------------------------------------|
	// | sd_depletion -> Predicted spawning biomass depletion level bt/Bo
	// | sd_log_sbt   -> Log Spawning biomass for each group.
	// |
	sdreport_vector sd_depletion(1,ngroup);	
	sdreport_matrix sd_log_sbt(1,ngroup,syr,nyr+1);
	


PRELIMINARY_CALCS_SECTION
	// |---------------------------------------------------------------------------------|
	// | Run the model with input parameters to simulate real data.
	// |---------------------------------------------------------------------------------|
	// | - nf is a function evaluation counter.
 	// | - SimFlag comes from the -sim command line argument to simulate fake data.
 	// |
  
  nf=0;
	if( testMSY )
	{
		testMSYxls();
	}
	if( SimFlag ) 
	{
		initParameters();
		
		simulationModel(rseed);
	}
	
	if (NewFiles)
	{
		generate_new_files();	
	}
	
	// CATCH POTENTIAL ERRORS FOR ARRAY BOUNDS ON M DEVS


	if( m_type ==2 && (min(m_nodeyear) < syr || max(m_nodeyear) > nyr) )
	{
		cerr<<"Nodes for natural mortality are outside the model dimensions."<<endl;
		COUT(min(m_nodeyear));
		COUT(syr);
		COUT(max(m_nodeyear));
		COUT(nyr);
		exit(1);
	}




	if(verbose) cout<<"||-- END OF PRELIMINARY_CALCS_SECTION --||"<<endl;
	


RUNTIME_SECTION
    maximum_function_evaluations 100,  200,   500, 25000, 25000
    convergence_criteria        0.01, 0.01, 1.e-3, 1.e-4, 1.e-5


PROCEDURE_SECTION
	
	initParameters();

	#ifndef NEW_SELEX
	calcSelectivities(isel_type);
	#endif

	#ifdef NEW_SELEX
	calcSelex();
	#endif

	calcTotalMortality();
	
	calcNumbersAtAge();
	
	calcTotalCatch();
	
	calcComposition();
	
	calcSurveyObservations();
	
	calcStockRecruitment();
	
	
	calcObjectiveFunction();



	if(sd_phase())
	{
		calcSdreportVariables();
	}
	
	
	if(mc_phase())
	{
		mcmcPhase=1;
	}
	
	if(mceval_phase())
	{
		mcmcEvalPhase=1;
		mcmc_output();
	}
	
	if( verbose ) {cout<<"End of main function calls"<<endl;}


FUNCTION saveXMLFile
	// TODO some day when I figure out Siberts' XML stuff.
	//ADMB_XMLDoc xml;


	/**
	Purpose:  This function calculates the sdreport variables.
	Author: Steven Martell
	
	Arguments:
		None
	
	NOTES:
		
	
	TODO list:
	  [?] - Calculate spawning biomass depletion for each group.
	*/
FUNCTION void calcSdreportVariables()
  {
	sd_depletion.initialize();
	sd_log_sbt.initialize();

	for(g=1;g<=ngroup;g++)
	{
		sd_depletion(g) = sbt(g)(nyr)/sbo(g);

		sd_log_sbt(g) = log(sbt(g));
	}

	

	if( verbose ) { cout<<"**** Ok after calcSdreportVariables ****"<<endl;}
  }


  	/**
  	Purpose: This function extracts the specific parameter values from the theta vector
  	       to initialize the leading parameters in the model.
  	Author: Steven Martell
  	
  	Arguments:
  		None
  	
  	NOTES:
  		- You must call this routine before running the simulation model to generate 
  		  fake data, otherwise you'll have goofy initial values for your leading parameters.
  		- Variance partitioning:
  	  Estimating total variance as = 1/precision
  	  and partition variance by rho = sig^2/(sig^2+tau^2).
  	  
  	  E.g. if sig = 0.2 and tau =1.12 then
  	  rho = 0.2^2/(0.2^2+1.12^2) = 0.03090235
  	  the total variance is kappa^2 = sig^2 + tau^2 = 1.2944
  	
  	TODO list:
  	[ ] - Alternative parameterization using MSY and FMSY as leading parameters (Martell).
  	[*] - avg recruitment limited to area, may consider ragged object for area & stock.
  	
  	*/
FUNCTION void initParameters()
  {
 	
  	int ih;
  	
	ro        = mfexp(theta(1));
	steepness = theta(2);
	m         = mfexp(theta(3));
	rho       = theta(6);
	sigma_r   = theta(7);
	//varphi    = sqrt(1.0/theta(7));
	//sig       = elem_prod(sqrt(rho) , varphi);
	//tau       = elem_prod(sqrt(1.0-rho) , varphi);

	for(ih=1;ih<=n_ag;ih++)
	{
		log_avgrec(ih)  = theta(4,ih);
		log_recinit(ih) = theta(5,ih);
	}
	

	
	switch(int(d_iscamCntrl(2)))
	{
		case 1:
			//Beverton-Holt model
			kappa = elem_div(4.*steepness,(1.-steepness));
			break;
		case 2:
			//Ricker model
			kappa = pow((5.*steepness),1.25);
		break;
	}
	
	if(verbose)cout<<"**** Ok after initParameters ****"<<endl;
	
  }
	
FUNCTION dvar_vector cubic_spline(const dvar_vector& spline_coffs)
  {
	RETURN_ARRAYS_INCREMENT();
	int nodes=size_count(spline_coffs);
	dvector ia(1,nodes);
	dvector fa(sage,nage);
	ia.fill_seqadd(0,1./(nodes-1));
	fa.fill_seqadd(0,1./(nage-sage));
	vcubic_spline_function ffa(ia,spline_coffs);
	RETURN_ARRAYS_DECREMENT();
	
	//some testing here
	/*dvar_vector spline_nodes(1,nodes);
		spline_nodes.fill_seqadd(-0.5,1./(nodes-1));
		cout<<spline_nodes<<endl;
		vcubic_spline_function test_ffa(ia,spline_nodes);
		cout<<test_ffa(fa)<<endl;
		exit(1);*/
	return(ffa(fa));
  }

FUNCTION dvar_vector cubic_spline(const dvar_vector& spline_coffs, const dvector& la)
  {
	/*interplolation for length-based selectivity coefficeients*/
	RETURN_ARRAYS_INCREMENT();
	int nodes=size_count(spline_coffs);
	dvector ia(1,nodes);
	ia.fill_seqadd(0,1./(nodes-1));
	dvector fa = (la-min(la))/(max(la)-min(la));
	vcubic_spline_function ffa(ia,spline_coffs);
	RETURN_ARRAYS_DECREMENT();
	return(ffa(fa));
  }

  /**
   * @brief cubic spline interpolation
   * @details Uses cubic spline interpolatoin for data type variables based on a 
   * vector of spline coefficients, or nodes, and independent points.  
   * The nodes are rescaled to 0-1.  This function does not extrapolate beyond the 
   * independent points.
   * 
   * @param spline_coffs a data vector of spline coefficients (nodes)
   * @param la a vector of independent points for use in interpolation.
   * 
   * @return A data vector containing the interpolated points.
   */
  
FUNCTION dvector cubic_spline(const dvector& spline_coffs, const dvector& la)
  {
	/*interplolation for length-based selectivity coefficeients*/
	//RETURN_ARRAYS_INCREMENT();
	int nodes=size_count(spline_coffs);
	dvector ia(1,nodes);
	ia.fill_seqadd(0,1./(nodes-1));
	dvector fa = (la-min(la))/(max(la)-min(la));
	vcubic_spline_function ffa(ia,spline_coffs);
	//RETURN_ARRAYS_DECREMENT();
	return(value(ffa(fa)));
	//return(1.0*la);
  }


FUNCTION calcSelex
  {
  	//cout<<"START of CalcSelex"<<endl;
  	log_sel.initialize();
  	
  	int i,j,k,kr;
  	
  	dvariable p1,p2;

  	kr = 0;
  	for(k = 1; k <= slx_nrow; k++)
  	{
  		// The following is used to mirror another gear-type
		// based on the absolute value of sel_phz.
		if(slx_phz(k) < 0)
		{
			kr = abs(slx_phz(k));
			slx_log_par(k) = slx_log_par(kr);
		}

		int yr1 = syr > slx_nsb(k)?syr:slx_nsb(k);
		int yr2 = nyr < slx_neb(k)?nyr:slx_neb(k);
		
		int nn = slx_nIpar(k)-1;
		
	  	slx::slxInterface<dvar_vector> *ptrSlx[nn];
	  	for( i = 0; i <= nn; i++ )
	  	{
	  		ptrSlx[i] = NULL;
	  	}
	  	slx::slxInterface<dvar_matrix> *ptrSlxM = NULL;

  		switch(slx_nSelType(k))
  		{
  			// logistic selectivity based on age.
  			case 1:
  				for( j = 0; j < slx_nIpar(k); j++ )
	  			{
  					p1 = slx_log_par(k,j+1,1);
  					p2 = slx_log_par(k,j+1,2);
  					ptrSlx[j] = new slx::slx_Logistic<dvar_vector>(age,p1,p2);
  				}
  			break;

  			// age-specific selectivity coefficients.
  			case 2:
  				for( j = 0; j < slx_nIpar(k); j++ )
	  			{
	  				dvar_vector slx_theta = slx_log_par(k)(j+1);
  					ptrSlx[j] = new slx::slx_Coefficients<dvar_vector>(age,slx_theta);
  				}
  			break;

  			// cubic spline
  			case 3:
  				for( j = 0; j < slx_nIpar(k); j++ )
	  			{
	  				dvar_vector slx_theta = slx_log_par(k)(j+1);
  					ptrSlx[j] = new slx::slx_CubicSpline<dvar_vector>(age,slx_theta);
  				}
  			break;

  			// • cubic spline over age/size each year
  			case 4:
  				for( j = 0; j < slx_nIpar(k); j++ )
	  			{
	  				dvar_vector slx_theta = slx_log_par(k)(j+1);
  					ptrSlx[j] = new slx::slx_CubicSpline<dvar_vector>(age,slx_theta);
  				}
  			break;

  			// • bicubic spline over age and year knots
  			case 5:
  				dvar_matrix tmp(yr1,yr2,sage,nage);
  				dvector iyr(1,slx_nYrNodes(k));
  				dvector iag(1,slx_nAgeNodes(k));
  				iyr.fill_seqadd(0,1.0/(slx_nYrNodes(k)-1));
  				iag.fill_seqadd(0,1.0/(slx_nAgeNodes(k)-1));
  				dvar_matrix slx_theta = slx_log_par(k);
  				tmp.initialize();
  				
  				ptrSlxM = new slx::slx_BiCubicSpline<dvar_matrix>(iag,iyr,slx_theta,tmp);
  			break;
  		}

	  	// fill arrays with selectivity coefficients.
	  	// NOTES:
		// • h = index for sex (0=both, 1=female, 2=male)
	  	// • If slx_nSex(k) == 0, then apply same slx curve to both sexes.
	  	//   Do this by looping over area and group, and assign to specific sex.
	  	j = 0;
	  	int f,g,h;
  		int h_sex = slx_nSex(k);  
		int kgear = slx_nGearIndex(k);
	  	for(int ig = 1; ig <= n_ags; ig++ )
		{
			f  = n_area(ig);
			g  = n_group(ig);
			h  = n_sex(ig);
			
			// if h_sex == 0, then you need to reset j = 0
			if ( h_sex == 0 ) j = 0;

			// if !h_sex, skip the process if current group is not the right sex
			if ( h_sex != 0 && h != h_sex) continue;
			int igrp = pntr_ags(f,g,h);
			// Fill vectors of selex
			if (ptrSlx[j])
			{
				for(i = yr1; i <= yr2; i++)
				{
					log_sel(kgear)(igrp)(i) = ptrSlx[j] -> Evaluate();
					if(slx_nSelType(k) == 4 && j < slx_nIpar(k)) j++;
				}
			}
			
			// Fill matrix of selex
			if (ptrSlxM)
			{
				log_sel(kgear)(igrp).sub(yr1,yr2) = ptrSlxM -> Evaluate();
			}

			//subtract mean to ensure mean(exp(log_sel))==1
			for(i = yr1; i <= yr2; i++)
			{
				log_sel(kgear)(igrp)(i) -= log( mean(mfexp(log_sel(kgear)(ig)(i))) );
			}
		}

		if( !ptrSlxM ) delete ptrSlxM;
		if( !*ptrSlx ) delete *ptrSlx;


  	}
  	
  	if(verbose==1) cout<<"End of CalcSelex"<<endl;
  	//exit(1);

  }


  	/**
  	Purpose: This function loops over each of ngears and calculates the corresponding
  	         selectivity coefficients for that gear in each year.  It uses a switch 
  	         statement based on isel_type to determine which selectivty function to use
  	         for each particular gear that is specified in the control file.  See NOTES
  	         below for more information on selectivity models.

  	Author: Steven Martell
  	
  	Arguments:
  		isel_type -> an ivector with integers that determine what selectivity model to use.
  	
  	NOTES:
  		- The following is a list of the current selectivity models that are implemented:
		1)  Logistic selectivity with 2 parameters.
		2)  Age-specific selectivity coefficients with (nage-sage) parameters.
		    and the last two age-classes are assumed to have the same selectivity.
		3)  A reduced age-specific parameter set based on a bicubic spline.
		4)  Time varying cubic spline.
		5)  Time varying bicubic spline (2d version).
		6)  Fixed logistic.
		7)  Logistic selectivity based on relative changes in mean weight at age
		8)  Time varying selectivity based on logistic with deviations in 
		    weights at age (3 estimated parameters).
		11) Logistic selectivity with 2 parameters based on mean length.
		12) Length-based selectivity using cubic spline interpolation.
  		
  		- The bicubic_spline function is located in stats.cxx library.
  	
  	TODO list:
  	[*] add an option for length-based selectivity.  Use inverse of
		allometric relationship w_a = a*l_a^b; to get mean length-at-age from
		empirical weight-at-age data, then calculate selectivity based on 
		mean length. IMPLEMENTED IN CASE 11

	[*] change index for gear loop from j to k, and be consistent with year (i) and
	    age (j), and sex (h) indexing.

  	*/
FUNCTION void calcSelectivities(const ivector& isel_type)
  {
	

	int ig,i,j,k,byr,bpar,kgear;
	double tiny=1.e-10;
	dvariable p1,p2,p3;
	dvar_vector age_dev=age;
	dvar_matrix t1;
	dvar_matrix   tmp(syr,nyr-1,sage,nage);
	dvar_matrix  tmp2(syr,nyr,sage,nage);
	dvar_matrix ttmp2(sage,nage,syr,nyr);
	
	// Selex cSelex(age);
	// logistic_selectivity cLogisticSelex(age);
	log_sel.initialize();

	for(kgear=1; kgear<=ngear; kgear++)
	{
		// The following is used to mirror another gear-type
		// based on the absolute value of sel_phz.
		k  = kgear;
		if(sel_phz(k) < 0)
		{
			k = abs(sel_phz(kgear));
			sel_par(kgear) = sel_par(k);
		}

		for( ig = 1; ig <= n_ags; ig++ )
		{
			tmp.initialize(); tmp2.initialize();
			dvector iy(1,yr_nodes(k));
			dvector ia(1,age_nodes(k));
			byr  = 1;
			bpar = 0; 
			switch(isel_type(k))
			{
				case 1: //logistic selectivity (2 parameters)
					for(i=syr; i<=nyr; i++)
					{
						if( i == sel_blocks(k,byr) )
						{
							bpar ++;
							if( byr < n_sel_blocks(k) ) byr++;
						}

						// cout<<"Testing selex class"<<endl;
						// log_sel(k)(ig)(i) = log( cSelex.logistic(sel_par(k)(bpar)) );
						// log_sel(k)(ig)(i) = log( cLogisticSelex(sel_par(k)(bpar)) );
						p1 = mfexp(sel_par(k,bpar,1));
						p2 = mfexp(sel_par(k,bpar,2));
						log_sel(kgear)(ig)(i) = log( plogis(age,p1,p2)+tiny );
					}
					break;
				
				case 6:	// fixed logistic selectivity
					p1 = mfexp(sel_par(k,1,1));
					p2 = mfexp(sel_par(k,1,2));
					for(i=syr; i<=nyr; i++)
					{
						log_sel(kgear)(ig)(i) = log( plogis(age,p1,p2) );
						// log_sel(k)(ig)(i) = log( cLogisticSelex(sel_par(k)(1)) );
					}
					break;
					
				case 2:	// age-specific selectivity coefficients
					for(i=syr; i<=nyr; i++)
					{
						if( i == sel_blocks(k,byr) )
						{
							bpar ++;
							if( byr < n_sel_blocks(k) ) byr++;
						}
						for(j=sage;j<=nage-1;j++)
						{
							log_sel(kgear)(ig)(i)(j)   = sel_par(k)(bpar)(j-sage+1);
						}
						log_sel(kgear)(ig)(i,nage) = log_sel(kgear)(ig)(i,nage-1);
					}
					break;
					
				case 3:	// cubic spline 
					for(i=syr; i<nyr; i++)
					{
						if( i==sel_blocks(k,byr) )
						{
							bpar ++;	
							log_sel(kgear)(ig)(i)=cubic_spline( sel_par(k)(bpar) );
							if( byr < n_sel_blocks(k) ) byr++;
						}
						log_sel(kgear)(ig)(i+1) = log_sel(kgear)(ig)(i);
					}
					break;
					
				case 4:	// time-varying cubic spline every year				
					for(i=syr; i<=nyr; i++)
					{
						log_sel(kgear)(ig)(i) = cubic_spline(sel_par(k)(i-syr+1));
					}
					break;
					
				case 5:	// time-varying bicubic spline
					ia.fill_seqadd( 0,1./(age_nodes(k)-1) );
					iy.fill_seqadd( 0,1./( yr_nodes(k)-1) );	
					bicubic_spline( iy,ia,sel_par(k),tmp2 );
					log_sel(kgear)(ig) = tmp2; 
					break;
					
				case 7:
					// time-varying selectivity based on deviations in weight-at-age
					// CHANGED This is not working and should not be used. (May 5, 2011)
					// SkDM:  I was not able to get this to run very well.
					// AUG 5, CHANGED so it no longer has the random walk component.
					p1 = mfexp(sel_par(k,1,1));
					p2 = mfexp(sel_par(k,1,2));
					
					for(i = syr; i<=nyr; i++)
					{
						dvar_vector tmpwt=log(d3_wt_avg(ig)(i)*1000)/mean(log(d3_wt_avg(ig)*1000.));
						log_sel(kgear)(ig)(i) = log( plogis(tmpwt,p1,p2)+tiny );
					}	 
					break;
					
				case 8:
					//Alternative time-varying selectivity based on weight 
					//deviations (d3_wt_dev) d3_wt_dev is a matrix(syr,nyr+1,sage,nage)
					//p3 is the coefficient that describes variation in log_sel.
					p1 = mfexp(sel_par(k,1,1));
					p2 = mfexp(sel_par(k,1,2));
					p3 = sel_par(k,1,3);
					
					for(i=syr; i<=nyr; i++)
					{
						tmp2(i) = p3*d3_wt_dev(ig)(i);
						log_sel(kgear)(ig)(i) = log( plogis(age,p1,p2)+tiny ) + tmp2(i);
					}
					break;
					
				case 11: // logistic selectivity based on mean length-at-age
					for(i=syr; i<=nyr; i++)
					{
						if( i == sel_blocks(k,byr) )
						{
							bpar ++;
							if( byr < n_sel_blocks(k) ) byr++;
						}
						p1 = mfexp(sel_par(k,bpar,1));
						p2 = mfexp(sel_par(k,bpar,2));

						dvector len = pow(d3_wt_avg(ig)(i)/d_a(ig),1./d_b(ig));

						log_sel(kgear)(ig)(i) = log( plogis(len,p1,p2) );
						//log_sel(kgear)(ig)(i) = log( plogis(len,p1,p2) );
					}	
					break;
					
				case 12: // cubic spline length-based coefficients.
					for(i=syr; i<=nyr; i++)
					{
						if( i == sel_blocks(k,byr) )
						{
							bpar ++;
							if( byr < n_sel_blocks(k) ) byr++;
						}
					
						dvector len = pow(d3_wt_avg(ig)(i)/d_a(ig),1./d_b(ig));
						log_sel(kgear)(ig)(i)=cubic_spline( sel_par(k)(bpar), len );
					}
					break;
					//parei aqui
				case 13:	// truncated age-specific selectivity coefficients

					for(i=syr; i<=nyr; i++)
					{
						if( i == sel_blocks(k,byr) )
						{
							bpar ++;
							if( byr < n_sel_blocks(k) ) byr++;
						}
						for(j=ahat_agemin(k); j<=ghat_agemax(k); j++)
						{
							log_sel(k)(ig)(i)(j)   = sel_par(k)(bpar)(j-ahat_agemin(k)+1);
						}
						
						for (j=ghat_agemax(k)+1; j<=nage; j++)
						{
							log_sel(kgear)(ig)(i,j) = log_sel(kgear)(ig)(i,ghat_agemax(k));
						}

						for(j=sage; j<ahat_agemin(k); j++)
						{
							log_sel(kgear)(ig)(i,j) = log_sel(kgear)(ig)(i,ahat_agemin(k));
						}						
					}
					break;
					
					
				default:
					log_sel(kgear)(ig)=0;
					break;
					
			}  // switch
			//subtract mean to ensure mean(exp(log_sel))==1
			for(i=syr;i<=nyr;i++)
			{
				log_sel(kgear)(ig)(i) -= log( mean(mfexp(log_sel(kgear)(ig)(i))) );
				// log_sel(k)(ig)(i) -= log( max(mfexp(log_sel(k)(ig)(i))) );
			}
			
		}  // end of nags
	}  //end of gear k

	if(verbose)cout<<"**** Ok after calcSelectivities ****"<<endl;
	
  }	

  	
	
  	/**
  	Purpose: This function calculates fishing mortality, total mortality and annual
  	         surivival rates S=exp(-Z) for each age and year based on fishing mortality
  	         and selectivity coefficients.  Z also is updated with time-varying 
  	         natural mortality rates if specificed by user.
  	Author: Steven Martell
  	
  	Arguments:
  		None
  	
  	NOTES:
  		- Jan 5, 2012 Added catch_type to allow for catch in numbers, weight or spawn.
          In the case of spawn on kelp (roe fisheries), the Fishing mortality does not
          occur on the adult component.  
        - Added if(catch_type(k)!=3) //exclude roe fisheries
  		- F(group,year,age)
  		- Exclude type = 3, roe fisheries harvesting eggs only, not adults.
		- if dCatchData$sex is male & female combined, then allocate to both sexes.

  	TODO list:
  	[*] Dec 24, 2010.  Adding time-varying natural mortality.
  	[*] May 20, 2011.  Add cubic spline to the time-varying natural mortality.
	[ ] Calculate average M for reference point calculations based on pfc file.
	[ ] April 16, 2014. Adjust ft_count for retrospective and prospective analyses.
  	*/
FUNCTION calcTotalMortality
  {

	int ig,ii,i,k,l;
	int ft_counter = 0;
	dvariable ftmp;
	F.initialize(); 
	ft.initialize();
	
	
	// |---------------------------------------------------------------------------------|
	// | FISHING MORTALITY
	// |---------------------------------------------------------------------------------|
	// |

	for(ig=1;ig<=nCtNobs;ig++)
	{
		i  = dCatchData(ig)(1);	 //year
		k  = dCatchData(ig)(2);  //gear
		f  = dCatchData(ig)(3);  //area
		g  = dCatchData(ig)(4);  //group
		h  = dCatchData(ig)(5);  //sex
		l  = dCatchData(ig)(6);  //type
		if( i < syr ) continue;
		if( i > nyr ) continue;
		ft_counter ++;
		if( h )
		{
			ii = pntr_ags(f,g,h);    
			ftmp = mfexp(log_ft_pars(ft_counter));
			ft(ii)(k,i) = ftmp;
			if( l != 3 )
			{
				F(ii)(i) += ftmp*mfexp(log_sel(k)(ii)(i));
			}
		}
		else if( !h ) // h=0 case for asexual catch
		{
			for(h=1;h<=nsex;h++)
			{
				ii = pntr_ags(f,g,h);    
				ftmp = mfexp(log_ft_pars(ft_counter));
				ft(ii)(k,i) = ftmp;
				if( l != 3 )
				{
					F(ii)(i) += ftmp*mfexp(log_sel(k)(ii)(i));
				}		
			}
		}
	}

	// |---------------------------------------------------------------------------------|
	// | NATURAL MORTALITY
	// |---------------------------------------------------------------------------------|
	// | - uses cubic spline to interpolate time-varying natural mortality
	M.initialize();
	log_m_devs.initialize();
	for(ig=1;ig<=n_ags;ig++)
	{
		g = n_group(ig);
		h = n_sex(ig);
		M(ig) = m( pntr_gs(g,h) );
		if( active( log_m_nodes) )
		{
			//int nodes = size_count(log_m_nodes);
			//dvector im(1,nodes);
			//dvector fm(syr+1,nyr);
			//im.fill_seqadd(0,1./(nodes-1));
			//fm.fill_seqadd(0,1./(nyr-syr));
			//vcubic_spline_function m_spline(im,log_m_nodes);
			//log_m_devs = m_spline( fm );
			switch( m_type )
			{
				case 0: 			// constant natural mortality
					log_m_devs = 0;
				break;

				case 1:
					// COUT("OK DUDE")
					// COUT(log_m_devs.indexmax());
					// COUT(log_m_nodes.shift(syr+1).indexmax());
					log_m_devs = log_m_nodes.shift(syr+1);
				break;

				case 2:
					dvector iyr = (m_nodeyear - syr) / (nyr-syr);
					dvector jyr(syr+1,nyr);
					jyr.fill_seqadd(0,1./(nyr-syr-1));
					// COUT(jyr);
					vcubic_spline_function vcsf(iyr,log_m_nodes);
					log_m_devs = vcsf(jyr);
				break;

			}


		}

		for(i=syr+1; i<=nyr; i++)
		{
			M(ig)(i) = M(ig)(i-1) * mfexp(log_m_devs(i));
		}
		// TODO fix for reference point calculations
		// m_bar = mean( M_tot.sub(pf_cntrl(1),pf_cntrl(2)) );
	}
	



	// |---------------------------------------------------------------------------------|
	// | TOTAL MORTALITY
	// |---------------------------------------------------------------------------------|
	// |
	for(ig=1;ig<=n_ags;ig++)
	{
		Z(ig) = M(ig) + F(ig);
		S(ig) = mfexp(-Z(ig));
	}

	if(verbose) cout<<"**** OK after calcTotalMortality ****"<<endl;	
  }
	
	
  	/**
  	Purpose: This function initializes the numbers-at-age matrix in syr
  	         based on log_rinit and log_init_rec_devs, the annual recruitment
  	         based on log_rbar and log_rec_devs, and updates the number-at-age
  	         over time based on the survival rate calculated in calcTotalMortality.

  	Author: Steven Martell
  	
  	Arguments:
  		None
  	
  	NOTES:
		- Aug 9, 2012.  Made a change here to initialize the numbers
		  at age in syr using the natural mortality rate at age in syr. 
		  Prior to this the average (m_bar) rate was used, since this 
		  has now changed with new projection control files.  Should only
		  affect models that were using time varying natural mortality.
  		- d_iscamCntrl(5) is a flag to start at unfished conditions, so set N(syr,sage) = ro
  	
  	TODO list:
  	[ ] - Restrict log_avgrec and rec_devs to area and group dimensions (remove sex).
  	[ ] - Initialize from unfished conditions (d_iscamCntrl 5 flag is true then rt(syr) = ro)
  	*/
FUNCTION calcNumbersAtAge
  {
	int ig,ih;

	N.initialize();
	bt.initialize();
	for(ig=1;ig<=n_ags;ig++)
	{
		f  = n_area(ig);
		g  = n_group(ig);
		ih = pntr_ag(f,g);

		dvar_vector lx(sage,nage);
		dvar_vector tr(sage,nage);
		lx(sage) = 1.0;
		for(j=sage;j< nage;j++)
		{
			lx(j+1) = lx(j) * exp( -M(ig)(syr)(j) );
		}
		lx(nage) /= (1.-exp(-M(ig)(syr,nage)));
		
		if( d_iscamCntrl(5) ) // initialize at unfished conditions.
		{
			tr =  log( ro(g) ) + log(lx);
		}
		else if ( !d_iscamCntrl(5) )
		{
			tr(sage)        = ( log_avgrec(ih)+log_rec_devs(ih)(syr));
			tr(sage+1,nage) = (log_recinit(ih)+init_log_rec_devs(ih));
			tr(sage+1,nage) = tr(sage+1,nage)+log(lx(sage+1,nage));
		}
		N(ig)(syr)(sage,nage) = 1./nsex * mfexp(tr);
		log_rt(ih)(syr-nage+sage,syr) = tr.shift(syr-nage+sage);


		for(i=syr;i<=nyr;i++)
		{
			if( i>syr )
			{
				log_rt(ih)(i) = (log_avgrec(ih)+log_rec_devs(ih)(i));
				N(ig)(i,sage) = 1./nsex * mfexp( log_rt(ih)(i) );				
			}

			N(ig)(i+1)(sage+1,nage) =++elem_prod(N(ig)(i)(sage,nage-1)
			                                     ,S(ig)(i)(sage,nage-1));
			N(ig)(i+1,nage)        +=  N(ig)(i,nage)*S(ig)(i,nage);

			// average biomass for group in year i
			bt(g)(i) += N(ig)(i) * d3_wt_avg(ig)(i);
		}
		N(ig)(nyr+1,sage) = 1./nsex * mfexp( log_avgrec(ih));
		bt(g)(nyr+1) += N(ig)(nyr+1) * d3_wt_avg(ig)(nyr+1);
	}
	
	if(verbose)cout<<"**** Ok after calcNumbersAtAge ****"<<endl;	
  }





  	/**
  	Purpose:  This function calculates the predicted age-composition samples (A) for 
  	          both directed commercial fisheries and survey age-composition data. For 
  	          all years of data specified in the A matrix, calculated the predicted 
  	          proportions-at-age in the sampled catch-at-age.  If no catch-age data exist
  	          for a particular year i, for gear k (i.e. no directed fishery or from a 
  	          survey sample process that does not have an appreciable F), the calculate 
  	          the predicted proportion based on log(N) + log_sel(group,gear,year)
  	Author: Steven Martell
  	
  	Arguments:
  		None
  	
  	NOTES:
  		- Adapted from iSCAM 1.5.  
  		- No longer using ragged arrays for gear, the ragged matrix is indexed by:
  		  year gear area, group, sex | age columns
  		- For the residuals, note that each gear is weigthed by the conditional MLE
  		  of the variance.
  	
  	TODO list:
  	[x] - Merge redundant code from calcCatchAtAge
  	[*] - Add case where Chat data do not exsist.
	[x] - Calculate residuals A_nu; gets done automatically in dmvlogistic
	[x] - add plus group if n_A_nage < nage;  Aug 7, 2013
	[ ] - Need to calculate probability of catching male or female of a given age. 
  	*/
  	
FUNCTION calcComposition
  {
  	int ii,ig,kk,e;
  	dvar_vector va(sage,nage);
  	dvar_vector fa(sage,nage);
  	dvar_vector sa(sage,nage);
  	dvar_vector za(sage,nage);
  	dvar_vector ca(sage,nage);
  	dvar_vector na(sage,nage);
  	dvar_vector ta(sage,nage);  // total numbers at age
  	A_hat.initialize();

  	 for(kk=1;kk<=nAgears;kk++)
  	 {
  	 	for(ii=1;ii<=n_A_nobs(kk);ii++)
  	 	{
	  		i = d3_A(kk)(ii)(n_A_sage(kk)-6);
	  		k = d3_A(kk)(ii)(n_A_sage(kk)-5);
	  		f = d3_A(kk)(ii)(n_A_sage(kk)-4);
	  		g = d3_A(kk)(ii)(n_A_sage(kk)-3);
	  		h = d3_A(kk)(ii)(n_A_sage(kk)-2);
	  		e = d3_A(kk)(ii)(n_A_sage(kk)-1);

	  		// | trap for retrospecitve analysis.
	  		if(i < syr) continue;
	  		if(i > nyr) continue;

	  		// total numbers-at-age
	  		// ta.initialize();
	  		// for( h = 1; h <= nsex; h++ )
	  		// {
	  		// 	ig = pntr_ags(f,g,h);
	  		// 	ta += N(ig)(i);
	  		// }

	  		if( h )  // age comps are sexed (h > 0)
	  		{
				ig = pntr_ags(f,g,h);
				va = mfexp(log_sel(k)(ig)(i));
				za = Z(ig)(i);
				sa = S(ig)(i);
				na = N(ig)(i);
				if( ft(ig)(k)(i)==0 )
				{
					ca = elem_prod(elem_prod(na,va),0.5*sa);
				}
				else
				{
					fa = ft(ig)(k)(i) * va;
					ca = elem_prod(elem_prod(elem_div(fa,za),1.-sa),na);					
				}
				//A_hat(kk)(ii) = ca(n_A_sage(kk),n_A_nage(kk));

				// | +group if n_A_nage(kk) < nage
				//if( n_A_nage(kk) < nage )
				//{
				//	A_hat(kk)(ii)(n_A_nage(kk)) += sum( ca(n_A_nage(kk)+1,nage) );
				//}
	  		}
	  		else if( !h )  // age-comps are unsexed
	  		{
	  			for(h=1;h<=nsex;h++)
	  			{
					ig = pntr_ags(f,g,h);
					va = mfexp(log_sel(k)(ig)(i));
					za = Z(ig)(i);
					sa = S(ig)(i);
					na = N(ig)(i);
					if( ft(ig)(k)(i)==0 )
					{
						ca = elem_prod(elem_prod(na,va),0.5*sa);
					}
					else
					{
						fa = ft(ig)(k)(i) * va;
						ca = elem_prod(elem_prod(elem_div(fa,za),1.-sa),na);					
					}
					//A_hat(kk)(ii) += ca(n_A_sage(kk),n_A_nage(kk));

					// | +group if n_A_nage(kk) < nage
					//if( n_A_nage(kk) < nage )
					//{
					//	A_hat(kk)(ii)(n_A_nage(kk)) += sum( ca(n_A_nage(kk)+1,nage) );
					//}
		  		}
	  		}

	  		// This is the age-composition
	  		// March 26, 2015.  Added ageing error matrix age_age
	  		if( n_ageFlag(kk) )
	  		{
	  			dvar_vector pred_ca = ca * age_age(e);
	  			A_hat(kk)(ii) = pred_ca(n_A_sage(kk),n_A_nage(kk));

	  			// predicted plus group age.
	  			if( n_A_nage(kk) < nage )
				{
					A_hat(kk)(ii)(n_A_nage(kk)) += sum( pred_ca(n_A_nage(kk)+1,nage) );
				}
	  		}
	  		else
	  		{
	  			/*
					This the catch-at-length composition.
					Pseudocode:
					-make an ALK
					-Ahat = ca * ALK
	  			*/
	  			dvar_vector mu = d3_len_age(ig)(i);
				dvar_vector sig= 0.1 * mu;
				dvector x(n_A_sage(kk),n_A_nage(kk));
				x.fill_seqadd(n_A_sage(kk),1);
				
				dvar_matrix alk = ALK(mu,sig,x);
	  			
	  			A_hat(kk)(ii) = ca * alk;
	  		}
	  		A_hat(kk)(ii) /= sum( A_hat(kk)(ii) );
  	 	}
  	}

	if(verbose)cout<<"**** Ok after calcComposition ****"<<endl;

  }	



FUNCTION calcTotalCatch
  {
  	/*
  	Purpose:  This function calculates the total catch.  
  	Dependencies: Must call calcCatchAtAge function first.
  	Author: Steven Martell
  	
  	Arguments:
  		None
  	
  	NOTES:
  		
  	
  	TODO list:
  	[X] get rid of the obs_ct, ct, eta array structures, inefficient, better to use
  	    a matrix, then cbind the predicted catch and residuals for report. (ie. an R
  	    data.frame structure and use melt to ggplot for efficient plots.)
  	*/
  	int ii,l,ig;
  	double d_ct;
  	double d_sd;

  	ct.initialize();
  	eta.initialize();
  	
  	dvar_vector     fa(sage,nage);
  	dvar_vector     ca(sage,nage);
  	dvar_vector     sa(sage,nage);
  	dvar_vector     za(sage,nage);
  	
  	

  	for(ii=1;ii<=nCtNobs;ii++)
	{
		i    = dCatchData(ii,1);
		k    = dCatchData(ii,2);
		f    = dCatchData(ii,3);
		g    = dCatchData(ii,4);
		h    = dCatchData(ii,5);
		l    = dCatchData(ii,6);
		d_ct = dCatchData(ii,7);
		d_sd = dCatchData(ii,8);// * d_ct;  this is SE(logspace)

  		
  		// | trap for retro year
  		if( i<syr ) continue;
  		if( i>nyr ) continue;


		switch(l)
		{
			case 1:  // catch in weight
				if( h )
				{
					ig     = pntr_ags(f,g,h);
					fa     = ft(ig)(k)(i) * mfexp(log_sel(k)(ig)(i));
					za     = Z(ig)(i);
					sa     = S(ig)(i);
					ca     = elem_prod(elem_prod(elem_div(fa,za),1.-sa),N(ig)(i));
					ct(ii) = ca * d3_wt_avg(ig)(i);
				}
				else if( !h )
				{
					for(h=1;h<=nsex;h++)
					{
						ig     = pntr_ags(f,g,h);
						fa     = ft(ig)(k)(i) * mfexp(log_sel(k)(ig)(i));
						za     = Z(ig)(i);
						sa     = S(ig)(i);
						ca     = elem_prod(elem_prod(elem_div(fa,za),1.-sa),N(ig)(i));
						ct(ii)+= ca * d3_wt_avg(ig)(i);		
					}
				}
			break;

			case 2:  // catch in numbers
				if( h )
				{
					ig     = pntr_ags(f,g,h);
					fa     = ft(ig)(k)(i) * mfexp(log_sel(k)(ig)(i));
					za     = Z(ig)(i);
					sa     = S(ig)(i);
					ca     = elem_prod(elem_prod(elem_div(fa,za),1.-sa),N(ig)(i));
					ct(ii) = sum( ca );
				}
				else if( !h )
				{
					for(h=1;h<=nsex;h++)
					{
						ig     = pntr_ags(f,g,h);
						fa     = ft(ig)(k)(i) * mfexp(log_sel(k)(ig)(i));
						za     = Z(ig)(i);
						sa     = S(ig)(i);
						ca     = elem_prod(elem_prod(elem_div(fa,za),1.-sa),N(ig)(i));
						ct(ii)+= sum( ca );
					}
				}
			break;

			case 3:  // roe fisheries, special case
				if( h )
				{
					ig            = pntr_ags(f,g,h);
					dvariable ssb = N(ig)(i) * d3_wt_mat(ig)(i);
					ct(ii)        = (1.-exp(-ft(ig)(k)(i))) * ssb;
				}
				else if( !h )
				{
					for(h=1;h<=nsex;h++)
					{
						ig            = pntr_ags(f,g,h);
						dvariable ssb = N(ig)(i) * d3_wt_mat(ig)(i);
						ct(ii)       += (1.-exp(-ft(ig)(k)(i))) * ssb;
					}
				}
			break;
		}	// end of switch

		// | standardized catch residual
		eta(ii) = (log(d_ct) - log(ct(ii)) + 0.5*square(d_sd)) / (d_sd);
	}
	if(verbose)cout<<"**** Ok after calcTotalCatch ****"<<endl;

  }


	
  	/**
  	Purpose:  This function computes the mle for survey q, calculates the survey 
  	          residuals (epsilon).
  	Author: Steven Martell
  	
  	Arguments:
  		None
  	
  	NOTES:
  		- Oct 31, 2010, added retrospective counter.
  		- Nov 22, 2010, adding multiple surveys. 
  		Still need to check with retrospective option
  		- Nov 30, 2010, adjust the suvery biomass by the fraction of Z that has occurred 
  		when the survey was conducted. For herring spawning biomass this would be 
  		after the fishery has taken place.
  		- Dec 6, 2010, modified predicted survey biomass to accomodate empirical
  		weight-at-age data (d3_wt_avg).
  		- May 11, 2011.  Vivian Haist pointed out an error in survey biomass comparison.
  		The spawning biomass was not properly calculated in this routine. I.e. its 
  		different than the spawning biomass in the stock-recruitment routine. (Based on 
  		fecundity which changes with time when given empirical weight-at-age data.)
  		- Jan 6, 2012.  CHANGED corrected spawn survey observations to include a roe 
  		fishery that would remove potential spawn that would not be surveyed.
  		- d3_survey_data: (iyr index(it) gear area group sex wt timing)
  		- for MLE of survey q, using weighted mean of zt to calculate q.
		- March 30, 2015.  Added deviation in q for random walk.

  	TODO list:
  	    [] - add capability to accomodate priors for survey q's.
  	    [] - verify q_prior=2 option for random walk in q.
  	    [ ] - For sel_type==3, may need to reduce abundance by F on spawning biomass (herring)
 
  */
FUNCTION calcSurveyObservations
  {
	
	int ii,kk,ig,nz;
	double di;
	dvariable ftmp,zbar;
	dvar_vector Na(sage,nage);
	dvar_vector va(sage,nage);
	dvar_vector sa(sage,nage);
	epsilon.initialize();
	qt.initialize();
	xi.initialize();
	it_hat.initialize();

	for(kk=1;kk<=nItNobs;kk++)
	{
		// | Vulnerable number-at-age to survey.
		dvar_matrix V(1,n_it_nobs(kk),sage,nage);
		V.initialize();
		nz = 0;
		int iz=1;  // index for first year of data for prospective analysis.
		for(ii=1;ii<=n_it_nobs(kk);ii++)
		{
			i    = d3_survey_data(kk)(ii)(1);
			k    = d3_survey_data(kk)(ii)(3);
			f    = d3_survey_data(kk)(ii)(4);
			g    = d3_survey_data(kk)(ii)(5);
			h    = d3_survey_data(kk)(ii)(6);
			di   = d3_survey_data(kk)(ii)(9);

			// | trap for retrospective nyr change
			if( i < syr )
			{
				iz ++;
				nz ++;
				continue;
			} 

			if( i > nyr ) continue;

			nz ++;  // counter for number of observations.

			// h ==0?h=1:NULL;
			Na.initialize();
			for(h=1;h<=nsex;h++)
			{
				ig  = pntr_ags(f,g,h);
				va  = mfexp( log_sel(k)(ig)(i) );
				sa  = mfexp( -Z(ig)(i)*di );
				Na  = elem_prod(N(ig)(i),sa);
				switch(n_survey_type(kk))
				{
					case 1:
						V(ii) += elem_prod(Na,va);
					break; 
					case 2:
						V(ii) += elem_prod(elem_prod(Na,va),d3_wt_avg(ig)(i));
					break;
					case 3:
						V(ii) += elem_prod(Na,d3_wt_mat(ig)(i));
					break;
				}
			}
		
		} // end of ii loop
		dvector     it = trans(d3_survey_data(kk))(2)(iz,nz);
		dvector     wt = trans(d3_survey_data(kk))(7)(iz,nz);
					wt = 1.0/square(exp(wt));
		            wt = wt/sum(wt);


		dvar_vector t1 = rowsum(V);
		dvar_vector zt = log(it);
		

		// | March 30, 2015. Issue #37.
		// | Added switch for 3 q_prior(kk) options.
		// | 	q_prior(kk) = 0 = constant fixed Q
		// | 	q_prior(kk) = 1 = constant MLE Q
		// | 	q_prior(kk) = 2 = penalized random walk in Q
		switch( q_prior(kk) )
		{
			case 0:		// Constant fixed Q
				q(kk)                  = exp(mu_log_q(kk));
				it_hat(kk).sub(iz,nz)  = q(kk) * t1(iz,nz);
				zt                     -=  log(it_hat(kk).sub(iz,nz));
			break;

			case 1:		// Constant MLE Q
				zt                     -= log(t1(iz,nz));
				zbar                   = sum(elem_prod(zt,wt));
				q(kk)                  = mfexp(zbar);
				
				// | survey residuals
				it_hat(kk).sub(iz,nz)  = q(kk) * t1(iz,nz);
				zt                     -= zbar;
				//epsilon(kk).sub(iz,nz) = elem_div(zt,it_log_se(kk)(iz,nz));
			break;

			case 2: 	// Penalized random walk in Q
				int jj = 1;  // index for qdevs.
				zt     -= log(t1(iz,nz));
				qt(kk)(iz)   = exp( zt(iz) + log_q_devs(kk)(jj) );
				for(ii=iz+1; ii<=nz; ii++)
				{
					jj ++;
					qt(kk)(ii) = qt(kk)(ii-1) * exp(log_q_devs(kk)(jj));
					
				}
				it_hat(kk).sub(iz,nz) = elem_prod(qt(kk)(iz,nz),t1(iz,nz));
				zt -= log(qt(kk)(iz,nz));
				q(kk) = qt(kk)(nz);
				//epsilon(kk).sub(iz,nz)= elem_div(zt,it_log_se(kk)(iz,nz));
			break;
		}

		// Standardized observation error residuals.
		epsilon(kk).sub(iz,nz) = elem_div(zt,it_log_se(kk)(iz,nz));

		// Standardized process error residuals.
		if(active(log_q_devs(kk)))
		{
			//dvar_vector fd_qt = first_difference( log_q_devs(kk) );
			dvar_vector fd_qt = first_difference( log(qt(kk)(iz,nz)) );
			xi(kk).sub(iz,nz-1) = elem_div(fd_qt.shift(iz),it_log_pe(kk)(iz,nz-1));
		}

//       TO BE DEPRECATED
//		// | SPECIAL CASE: penalized random walk in q process error only.
//		if( q_prior(kk)==2 )
//		{
//			epsilon(kk).initialize();
//			dvar_vector fd_zt     = first_difference(zt);
//			dvariable  zw_bar     = sum(elem_prod(fd_zt,wt(iz,nz-1)));
//			epsilon(kk).sub(iz,nz-1) = elem_div(fd_zt - zw_bar,it_log_se(kk)(iz,nz-1));
//			qt(kk)(iz) = exp(zt(iz));
//			for(ii=iz+1;ii<=nz;ii++)
//			{
//				qt(kk)(ii) = qt(kk)(ii-1) * exp(fd_zt(ii-1));
//			}
//			it_hat(kk).sub(iz,nz) = elem_prod(qt(kk)(iz,nz),t1(iz,nz));
//		}
//
//		// | MIXED ERROR MODEL for random walk in q
//		if( q_prior(kk)==3 )
//		{
//			dvar_vector proerr = zt - zbar;
//			qt(kk)(ii) = exp(zbar + proerr(iz));
//			for(ii=iz+1;ii<=nz;ii++)
//			{
//				proerr(ii) = zt(ii) - zt(ii-1);
//				qt(kk)(ii) = qt(kk)(ii-1) * exp(proerr(ii));
//			}
//			xi(kk).sub(iz,nz)     = elem_div(proerr,it_log_pe(kk)(iz,nz));
//			it_hat(kk).sub(iz,nz) = elem_prod(qt(kk)(iz,nz),t1(iz,nz));
//		}
	}
	if(verbose)cout<<"**** Ok after calcSurveyObservations ****"<<endl;
	
  }

  
  	/**
	Purpose:  
		This function is used to derive the underlying stock-recruitment 
		relationship that is ultimately used in determining MSY-based reference 
		points.  The objective of this function is to determine the appropriate 
		Ro, Bo and steepness values of either the Beverton-Holt or Ricker  Stock-
		Recruitment Model:

		Beverton-Holt Model
		\f$ Rt=k*Ro*St/(Bo+(k-1)*St)*exp(delta-0.5*tau*tau) \f$

		Ricker Model
		\f$ Rt=so*St*exp(-beta*St)*exp(delta-0.5*tau*tau) \f$
			
		The definition of a stock is based on group only. At this point, spawning biomass
		from all areas for a given group is the assumed stock, and the resulting
		recruitment is compared with the estimated recruits|group for all areas.

  	Author: Steven Martell
  	
  	Arguments:
  		None
  	
  	NOTES:
		Psuedocode:
		-1) Get average natural mortality rate at age.
		-2) Calculate survivorship to time of spawning.
		-3) Calculate unfished spawning biomass per recruit.
		-4) Compute spawning biomass vector & substract roe fishery
		-5) Project spawning biomass to nyr+1 under natural mortality.
		-6) Calculate stock recruitment parameters (so, beta);
		-7) Calculate predicted recruitment
		-8) Compute residuals from estimated recruitments.
  			
  	
  	TODO list:
	  [?] - Change step 3 to be a weighted average of spawning biomass per recruit by area.
	  [?] - Increase dimensionality of ro, sbo, so, beta, and steepness to ngroup.
	  [X] - Add autocorrelation in recruitment residuals with parameter \f$ \gamma_r \f$.

  	*/
FUNCTION void calcStockRecruitment()
  {

  	int ig,ih;
  	rt.initialize();
  	sbt.initialize();
  	delta.initialize();
	
	//dvariable phib;//,so,beta;
	dvector         fa(sage,nage);
	dvar_vector   stmp(sage,nage);
	dvar_vector     ma(sage,nage);
	dvar_vector tmp_rt(syr+sage,nyr);
	dvar_vector     lx(sage,nage); 
	dvar_vector     lw(sage,nage);
    dvar_vector    tau = sigma_r;
	
	
	for(g=1;g<=ngroup;g++)
	{
		lx.initialize();
		lw.initialize();
		lx(sage) = 1.0;
		lw(sage) = 1.0;
		phib = 0;
		for(f=1;f<=narea;f++)
		{
			for(h=1;h<=nsex;h++)
			{
				ig = pntr_ags(f,g,h);

				// | Step 1. average natural mortality rate at age.
				// | Step 2. calculate survivorship
				for(j=sage;j<=nage;j++)
				{
					ma(j) = mean(trans(M(ig))(j));
					fa(j) = mean( trans(d3_wt_mat(ig))(j) );
					if(j > sage)
					{
						lx(j) = lx(j-1) * mfexp(-ma(j-1));
					}
					lw(j) = lx(j) * mfexp(-ma(j)*d_iscamCntrl(13));
				}
				lx(nage) /= 1.0 - mfexp(-ma(nage));
				lw(nage) /= 1.0 - mfexp(-ma(nage));
				
				// | Step 3. calculate average spawing biomass per recruit.
				phib += 1./(narea*nsex) * lw*fa;

				// | Step 4. compute spawning biomass at time of spawning.
				for(i=syr;i<=nyr;i++)
				{
					stmp      = mfexp(-Z(ig)(i)*d_iscamCntrl(13));
					sbt(g,i) += elem_prod(N(ig)(i),d3_wt_mat(ig)(i)) * stmp;
				}

				// | Step 5. spawning biomass projection under total mortality only.
				stmp          = mfexp(-Z(ig)(nyr)*d_iscamCntrl(13));
				sbt(g,nyr+1) += elem_prod(N(ig)(nyr+1),d3_wt_mat(ig)(i)) * stmp;
			}

			// | Estimated recruits
			ih     = pntr_ag(f,g);
			rt(g) += mfexp(log_rt(ih)(syr+sage,nyr));
		}

		// | Step 6. calculate stock recruitment parameters (so, beta, sbo);
		so(g)  = kappa(g)/phib;
		sbo(g) = ro(g) * phib;

		// | Step 7. calculate predicted recruitment.
		dvar_vector tmp_st = sbt(g)(syr,nyr-sage).shift(syr+sage);
		switch(int(d_iscamCntrl(2)))
		{
			case 1:  // | Beverton Holt model
				beta(g)   = (kappa(g)-1.)/sbo(g);
				tmp_rt    = elem_div(so(g)*tmp_st,1.+beta(g)*tmp_st);
			break;

			case 2:  // | Ricker model
				beta(g)   = log(kappa(g))/sbo(g);
				tmp_rt    = elem_prod(so(g)*tmp_st,exp(-beta(g)*tmp_st));
			break;
		}
		
		// | Step 8. // residuals in stock-recruitment curve with gamma_r = 0

		delta(g) = log(rt(g))-log(tmp_rt)+0.5*tau(g)*tau(g);

		// Autocorrelation in recruitment residuals.
		// if gamma_r > 0 then 
		if( active(theta(6)) )
		{
			int byr = syr+sage+1;	
			delta(g)(byr,nyr) 	= log(rt(g)(byr,nyr)) 
									- (1.0-rho(g))*log(tmp_rt(byr,nyr)) 
									- rho(g)*log(++rt(g)(byr-1,nyr-1))
									+ 0.5*tau(g)*tau(g);			
		}


	}
	
	if(verbose)cout<<"**** Ok after calcStockRecruitment ****"<<endl;
	
  }
	
FUNCTION calcObjectiveFunction
  {
  	/*
  	Purpose:  This function computes the objective function that ADMB will minimize.
  	Author: Steven Martell
  	
  	Arguments:
  		None
  	
  	NOTES:
		There are several components to the objective function
		Likelihoods (nlvec):
			-1) likelihood of the catch data
			-2) likelihood of the survey abundance index
			-3) likelihood component for random walk in q.
			-4) likelihood of age composition data 
			-5) likelihood for stock-recruitment relationship
			-6) penalized likelihood for fishery selectivities
			-7) penalized likelihood for fishery selectivities
  		
  	
  	TODO list:
	[*]	- Dec 20, 2010.  SJDM added prior to survey qs.
		  q_prior is an ivector with current options of 0 & 1 & 2.
		  0 is a uniform density (ignored) and 1 is a normal
		  prior density applied to log(q), and 2 is a random walk in q.
  	[] - Allow for annual sig_scaler values in catch data likelihood.
  	[ ] - Increase dimensionality of sig and tau to ngroup.
  	[ ] - Correct likelihood for cases when rho > 0 (Schnute & Richards, 1995)
  	*/



// 	int i,j,k;
// 	double o=1.e-10;

	nlvec.initialize();


	
	// |---------------------------------------------------------------------------------|
	// | LIKELIHOOD FOR CATCH DATA
	// |---------------------------------------------------------------------------------|
	// | - This likelihood changes between phases n-1 and n:
	// | - Phase (n-1): standard deviation in the catch based on user input d_iscamCntrl(3)
	// | - Phase (n)  : standard deviation in the catch based on user input d_iscamCntrl(4)
	// | 

	double sig_scaler =d_iscamCntrl(3);
	if(last_phase())
	{
		sig_scaler=d_iscamCntrl(4);
	}
	if( active(log_ft_pars) )
	{
		for(int i = 1; i<= nCtNobs; i++)
		{
			int iyr = dCatchData(i,1);
			if ( iyr < syr ) continue;
			if ( iyr > nyr ) continue;
			nlvec(1) += dnorm(eta(i),0.0,1.0*sig_scaler);
		}
	}




	// |---------------------------------------------------------------------------------|
	// | LIKELIHOOD FOR RELATIVE ABUNDANCE INDICES
	// |---------------------------------------------------------------------------------|
	// | - sig_it     -> vector of standard deviations based on relative wt for survey.
	// |
	for(k=1;k<=nItNobs;k++)
	{
		for( i = 1; i <= n_it_nobs(k); i++ )
		{
			int iyr = d3_survey_data(k)(i,1);
			if (iyr < syr) continue;
			if (iyr > nyr) continue;
			nlvec(2,k) += dnorm(epsilon(k)(i),0.0,1.0);
		}
		
		if(active(log_q_devs(k)))
		{
			nlvec(3,k)=dnorm(xi(k),1.0);
		}
	}
	
	// |---------------------------------------------------------------------------------|
	// | LIKELIHOOD FOR AGE-COMPOSITION DATA
	// |---------------------------------------------------------------------------------|
	// | - Two options based on d_iscamCntrl(14):
	// | - 	1 -> multivariate logistic using conditional MLE of the variance for weight.
	// | -  2 -> multnomial, assumes input sample size as n in n log(p)
    // | -  3 -> logistic normal w no autocorrelation.
	// | -  Both likelihoods pool pmin (d_iscamCntrl(16)) into adjacent yearclass.
	// | -  PSEUDOCODE:
	// | -    => first determine appropriate dimensions for each of nAgears arrays (naa)
	// | -    => second extract sub arrays into obs (O) and predicted (P)
	// | -    => Compute either dmvlogistic, or dmultinom negative loglikehood.
	// | 
	// | TODO:
	// | [ ] - change A_nu to data-type variable, does not need to be differentiable.
	// | [ ] - issue 29. Fix submatrix O, P for prospective analysis & sex/area/group.

	// Testing new abstract compositionLikelihood class. SUXS.

	//acl::negLogLikelihood<dmatrix,dvar_matrix> *ptr_AgeCompLike[nAgears-1];


	


	A_nu.initialize();
	for(k=1;k<=nAgears;k++)
	{	
		
		if( n_A_nobs(k)>0 )
		{
			//int n_naa = 0;		//retrospective counter
			//int n_saa = 1;		//prospective counter
			int iyr;
			dmatrix      O(n_saa(k),n_naa(k),n_A_sage(k),n_A_nage(k));
			dvar_matrix  P(n_saa(k),n_naa(k),n_A_sage(k),n_A_nage(k));
			dvar_matrix nu(n_saa(k),n_naa(k),n_A_sage(k),n_A_nage(k));
			O.initialize();
			P.initialize();
			nu.initialize();
			
			int ii=n_saa(k);
			for(i=1;i<=n_A_nobs(k);i++)
			{
				iyr = d3_A(k)(i)(n_A_sage(k)-6);	//index for year
				if(iyr >= syr && iyr <= nyr)
				{
					O(ii) = d3_A_obs(k)(i).sub(n_A_sage(k),n_A_nage(k));
					P(ii) = A_hat(k)(i).sub(n_A_sage(k),n_A_nage(k));
					ii ++;
				}
			}
			

			
			//dmatrix     O = trans(trans(d3_A_obs(k)).sub(n_A_sage(k),n_A_nage(k))).sub(iaa,naa);
			//dvar_matrix P = trans(trans(A_hat(k)).sub(n_A_sage(k),n_A_nage(k))).sub(iaa,naa);
			//dvar_matrix nu(O.rowmin(),O.rowmax(),O.colmin(),O.colmax()); 
			
			// | Choose form of the likelihood based on d_iscamCntrl(14) switch
			//switch(int(d_iscamCntrl(14)))



			logistic_normal cLN_Age( O,P,dMinP(k),dEps(k) );
			
			//cout<<"cLN_Age is "<<cLN_Age<<endl;

			logistic_student_t cLST_Age( O,P,dMinP(k),dEps(k) );



			switch( int(nCompLikelihood(k)) )
			{
				case 1:	// multivariate Logistic
					
					nlvec(4,k) = dmvlogistic(O,P,nu,age_tau2(k),dMinP(k));
					//cout<<"like: "<<endl<<" "<<nlvec(4,k)<<endl;
					// ptr_AgeCompLike[k-1] = new acl::multivariteLogistic<dvariable,dmatrix,dvar_matrix>(O,P,dMinP(k)); 
					// nlvec(4,k)      = ptr_AgeCompLike[k-1] -> nloglike();
					// nu              = ptr_AgeCompLike[k-1] -> residual();

				break;

				case 2:	// multinomial with fixed sample size.
					//ptr_AgeCompLike[k-1] = new acl::multinomial<dvariable,dmatrix,dvar_matrix>(O,P,dMinP(k));
					//nlvec(4,k) = ptr_AgeCompLike[k-1] -> nloglike();
					//nu         = ptr_AgeCompLike[k-1] -> residual();
					//COUT(nlvec(4,k));
					nlvec(4,k) = dmultinom(O,P,nu,age_tau2(k),dMinP(k));
					//COUT(nlvec(4,k));
					//exit(1);
				break;

				case 6: // Multinomial with estimated effective sample size.
					//ptr_AgeCompLike[k-1] = new acl::multinomial<dvariable,dmatrix,dvar_matrix>(O,P,log_degrees_of_freedom(k),dMinP(k));
					//nlvec(4,k) = ptr_AgeCompLike[k-1] -> nloglike();
					//nu         = ptr_AgeCompLike[k-1] -> residual();
					// deprecate
					nlvec(4,k) = mult_likelihood(O,P,nu,log_degrees_of_freedom(k));

				break; 

				case 3:
					if( !active(log_age_tau2(k)) )                 // LN1 Model
					{
						nlvec(4,k)  = cLN_Age();	
					}
					else
					{
						nlvec(4,k) = cLN_Age( exp(log_age_tau2(k)) );
					}

					// Residual
					if(last_phase())
					{
						nu          = cLN_Age.get_standardized_residuals();
						age_tau2(k) = cLN_Age.get_sigma2();
					}
				break;
				

				case 4:
					//logistic_normal cLN_Age( O,P,dMinP(k),dEps(k) );
					if( active(phi1(k)) && !active(phi2(k)) )  // LN2 Model
					{
						nlvec(4,k)   = cLN_Age(exp(log_age_tau2(k)),phi1(k));	
					}
					if( active(phi1(k)) && active(phi2(k)) )   // LN3 Model
					{
						nlvec(4,k)   = cLN_Age(exp(log_age_tau2(k)),phi1(k),phi2(k));	
					}

					// Residual
					if(last_phase())
					{
						nu          = cLN_Age.get_standardized_residuals();
						age_tau2(k) = cLN_Age.get_sigma2();
					}

				break;

				case 5: // Logistic-normal with student-t
					if( !active(log_degrees_of_freedom(k)) )
					{
						nlvec(4,k) = cLST_Age();
					}
					else
					{
						nlvec(4,k) = cLST_Age(exp(log_degrees_of_freedom(k)));
					}

					// Residual
					if(last_phase())
					{
						nu          = cLST_Age.get_standardized_residuals();
						age_tau2(k) = cLST_Age.get_sigma2();
					}
				break;
				case 7: // Multivariate-t 
					nlvec(4,k) = multivariate_t_likelihood(O,P,log_age_tau2(k),
					                                       log_degrees_of_freedom(k),
					                                       phi1(k),nu);
					age_tau2(k) = exp(value(log_age_tau2(k)));
					cout<<"Here we go dude"<<endl;
				break;
			}
			
			
			// | Extract residuals.
			for(i=n_saa(k);i<=n_naa(k);i++)
			{
				A_nu(k)(i)(n_A_sage(k),n_A_nage(k))=nu(i);
			}
			ii = n_saa(k);
			for( i = 1; i <= n_A_nobs(k); i++ )
			{
				iyr = d3_A(k)(i)(n_A_sage(k)-6);	//index for year
				if(iyr >= syr && iyr <= nyr)
				{
					A_nu(k)(i)(n_A_sage(k),n_A_nage(k))=nu(ii++);		
				}
			}
		}
	}


	//if(ptr_AgeCompLike != NULL)
	//{
	//	delete *ptr_AgeCompLike;
	//	cout<<"It was deleted"<<endl;
	//} 

	
	// |---------------------------------------------------------------------------------|
	// | STOCK-RECRUITMENT LIKELIHOOD COMPONENT
	// |---------------------------------------------------------------------------------|
	// | - tau is the process error standard deviation.
	if( active(theta(1)) || active(theta(2)) )
	{
		for(g=1;g<=ngroup;g++)
		{
			nlvec(5,g) = dnorm(delta(g),sigma_r(g));
		}
	}

	// |---------------------------------------------------------------------------------|
	// | LIKELIHOOD COMPONENTS FOR SELECTIVITY PARAMETERS
	// |---------------------------------------------------------------------------------|
	// | - lambda_1  -> penalty weight for smoothness
	// | - lambda_2  -> penalty weight for dome-shape
	// | - lambda_3  -> penalty weight for inter-annual variation.
	dvar_vector lvec(1,7); 
	lvec.initialize();
	int ig;
	#ifdef NEW_SELEX
	for(int kr = 1; kr <= slx_nrow; kr++ )
	{
		int yr1 = syr>slx_nsb(kr)?syr:slx_nsb(kr);
		int yr2 = nyr<slx_neb(kr)?nyr:slx_neb(kr);
		k = slx_nGearIndex(kr);
		if( active(slx_log_par(kr)) )
		{
			// penalty in curviture  (nlvec(6,k)).
			// penalty in dome-shape (nlvec(7,k)).
			if( slx_nSelType(kr) != 1)
			{
				for( ig = 1; ig <= n_ags; ig++ )
				{
					for( i = yr1; i <= yr2; i++ )
					{
						dvar_vector df1 = first_difference(log_sel(k)(ig)(i));
						dvar_vector df2 = first_difference(df1);
						nlvec(6,k)     += slx_lam1(k)/(nage-sage+1)*norm2(df2);

						for( j = sage; j <  nage; j++ )
						{
							dvariable diff = log_sel(k,ig,i,j) - log_sel(k,ig,i,j+1);
							if(diff > 0)
							{
								nlvec(7,k) += slx_lam2(k) * square(diff);
							}
						}
					}
				}
			}

			// penalty in time-varying changes (nlvec(8,k)).
			if( slx_nSelType(kr) == 4 || slx_nSelType(kr) == 5)
			{
				for(ig=1;ig<=n_ags;ig++)
				{
					dvar_matrix trans_log_sel = trans( log_sel(k)(ig) );
					for(j=sage;j<=nage;j++)
					{
						dvar_vector df1 = first_difference(trans_log_sel(j));
						dvar_vector df2 = first_difference(df1);
						nlvec(8,k)     += slx_lam3(k)/(nage-sage+1)*norm2(df2);
					}
				}
			}
		}
		
	}
	#endif

	#ifndef NEW_SELEX
	for(k=1;k<=ngear;k++)
	{

		if( active(sel_par(k)) )
		{
			//if not using logistic selectivity then
			//CHANGED from || to &&  May 18, 2011 Vivian
			if( isel_type(k)!=1 && 
				isel_type(k)!=7 && 
				isel_type(k)!=8 &&
				isel_type(k)!=11 )  
			{
				for(ig=1;ig<=n_ags;ig++)
				{
				for(i=syr;i<=nyr;i++)
				{
					//curvature in selectivity parameters
					dvar_vector df2 = first_difference(first_difference(log_sel(k)(ig)(i)));
					nlvec(6,k)     += lambda_1(k)/(nage-sage+1)*df2*df2;

					//penalty for dome-shapeness
					for(j=sage;j<=nage-1;j++)
						if(log_sel(k,ig,i,j)>log_sel(k,ig,i,j+1))
							nlvec(7,k)+=lambda_2(k)
										*square( log_sel(k,ig,i,j)-log_sel(k,ig,i,j+1) );
				}
				}
			}
			
			/*
			Oct 31, 2012 Halloween! Added 2nd difference penalty on time 
			for isel_type==(4)

			Mar 13, 2013, added 2nd difference penalty on isel_type==5 
			*/
			if( lambda_3(k) && 
				  (isel_type(k)==4 ||
				   isel_type(k)==5 || 
				   n_sel_blocks(k) > 1) 
			  )
			{
				for(ig=1;ig<=n_ags;ig++)
				{
					
				dvar_matrix trans_log_sel = trans( log_sel(k)(ig) );
				for(j=sage;j<=nage;j++)
				{
					dvar_vector df2 = first_difference(first_difference(trans_log_sel(j)));
					nlvec(8,k)     +=  lambda_3(k)/(nage-sage+1)*norm2(df2);
				}
				}
			}
			
		}
	}
	#endif
	
	// |---------------------------------------------------------------------------------|
	// | CONSTRAINTS FOR SELECTIVITY DEVIATION VECTORS
	// |---------------------------------------------------------------------------------|
	// | [?] - TODO for isel_type==2 ensure mean 0 as well.
	// |

	#ifdef NEW_SELEX
	for(k=1;k<=slx_nrow;k++)
	{
		if( active(slx_log_par(k)) && slx_nSelType(k)!=1 )
		{
			dvariable s = 0;
			//bicubic spline version ensure col mean = 0
			if(slx_nSelType(k)==5)  
			{
				dvar_matrix tmp = trans(slx_log_par(k));
				for(j=1;j<=tmp.rowmax();j++)
				{
					s=mean(tmp(j));
					lvec(1)+=10000.0*s*s;
				}
			}

			if( slx_nSelType(k)==2 ||
			    slx_nSelType(k)==3 ||
			 	slx_nSelType(k)==4 || 
				slx_nSelType(k)==12 )
			{
				dvar_matrix tmp = slx_log_par(k);
				for(j=1;j<=tmp.rowmax();j++)
				{
					s=mean(tmp(j));
					lvec(1)+=10000.0*s*s;
				}
			}
		}
	}
	#endif

	#ifndef NEW_SELEX
	for(k=1;k<=ngear;k++)
	{
		if( active(sel_par(k)) &&
			isel_type(k)!=1    &&
			isel_type(k)!=7    &&
			isel_type(k)!=8    &&
			isel_type(k)!=11 )
		{
			dvariable s = 0;
			if(isel_type(k)==5)  //bicubic spline version ensure column mean = 0
			{
				dvar_matrix tmp = trans(sel_par(k));
				for(j=1;j<=tmp.rowmax();j++)
				{
					s=mean(tmp(j));
					lvec(1)+=10000.0*s*s;
				}
			}
			if( isel_type(k)==2 ||
			    isel_type(k)==3 ||
			 	isel_type(k)==4 || 
				isel_type(k)==12 )
			{
				dvar_matrix tmp = sel_par(k);
				for(j=1;j<=tmp.rowmax();j++)
				{
					s=mean(tmp(j));
					lvec(1)+=10000.0*s*s;
				}
			}
		}
	}
	#endif
	
	
	// |---------------------------------------------------------------------------------|
	// | PRIORS FOR LEADING PARAMETERS p(theta)
	// |---------------------------------------------------------------------------------|
	// | - theta_prior is a switch to determine which statistical distribution to use.
	// |
	dvariable ptmp; 
	dvar_vector priors(1,npar);
	priors.initialize();
	for(i=1;i<=npar;i++)
	{
		ptmp = 0;
		for(j=1;j<=ipar_vector(i);j++)
		{
			if( active(theta(i)) )
			{
				switch(theta_prior(i))
				{
				case 1:		//normal
					ptmp += dnorm(theta(i,j),theta_control(i,6),theta_control(i,7));
					break;
					
				case 2:		//lognormal CHANGED RF found an error in dlnorm prior. rev 116
					ptmp += dlnorm(theta(i,j),theta_control(i,6),theta_control(i,7));
					break;
					
				case 3:		//beta distribution (0-1 scale)
					double lb,ub;
					lb=theta_lb(i);
					ub=theta_ub(i);
					ptmp += dbeta((theta(i,j)-lb)/(ub-lb),theta_control(i,6),theta_control(i,7));
					break;
					
				case 4:		//gamma distribution
					ptmp += dgamma(theta(i,j),theta_control(i,6),theta_control(i,7));
					break;
					
				default:	//uniform density
					ptmp += log(1./(theta_control(i,3)-theta_control(i,2)));
					break;
				}
			}
		}
		priors(i) = ptmp;	
	}
	
	// |---------------------------------------------------------------------------------|
	// | PRIOR FOR SURVEY Q
	// |---------------------------------------------------------------------------------|
	// |
	dvar_vector qvec(1,nits);
	qvec.initialize();
	for(k=1;k<=nits;k++)
	{
		if(q_prior(k) == 1 && sd_log_q(k) != 0 )
		{
			qvec(k) = dnorm( log(q(k)), mu_log_q(k), sd_log_q(k) );
		}
	}
	
	
// 	//** Legacy **  By accident took Rick Methot's bag from Nantes.
// 	//301 787 0241  Richard Methot cell phone.
// 	//ibis charles du gaulle at
// 	//01 49 19 19 20
	

	// |---------------------------------------------------------------------------------|
	// | LIKELIHOOD PENALTIES TO REGULARIZE SOLUTION
	// |---------------------------------------------------------------------------------|
	// | - pvec(1)  -> penalty on mean fishing mortality rate.
	// | - pvec(2)  -> penalty on first difference in natural mortality rate deviations.
	// | - pvec(4)  -> penalty on recruitment deviations.
	// | - pvec(5)  -> penalty on initial recruitment vector.
	// | - pvec(6)  -> constraint to ensure sum(log_rec_dev) = 0
	// | - pvec(7)  -> constraint to ensure sum(init_log_rec_dev) = 0
	// |
	dvar_vector pvec(1,7);
	pvec.initialize();
	
	dvariable log_fbar = mean(log_ft_pars);
	if(last_phase())
	{
		
		pvec(1) = dnorm(log_fbar,log(d_iscamCntrl(7)),d_iscamCntrl(9));
		
		// | Penalty for log_rec_devs (large variance here)
		for(g=1;g<=n_ag;g++)
		{
			pvec(4) += dnorm(log_rec_devs(g),2.0);
			pvec(5) += dnorm(init_log_rec_devs(g),2.0);
			dvariable s = 0;
			s = mean(log_rec_devs(g));
			pvec(6) += 1.e5 * s*s;
			s = mean(init_log_rec_devs(g));
			pvec(7) += 1.e5 * s*s;
		}
	}
	else
	{

		pvec(1) = dnorm(log_fbar,log(d_iscamCntrl(7)),d_iscamCntrl(8));
		
		//Penalty for log_rec_devs (CV ~ 0.0707) in early phases
		for(g=1;g<=n_ag;g++)
		{
			pvec(4) += 100.*norm2(log_rec_devs(g));
			pvec(5) += 100.*norm2(init_log_rec_devs(g));
			dvariable s = 0;
			s = mean(log_rec_devs(g));
			pvec(6) += 1.e5 * s*s;
			s = mean(init_log_rec_devs(g));
			pvec(7) += 1.e5 * s*s;
		}
	}
	
	if(active(log_m_nodes))
	{
		// double std_mdev = d_iscamCntrl(11);
		dvar_vector fd_mdevs=first_difference(log_m_devs);
		pvec(2)  = dnorm(fd_mdevs,m_stdev);
		pvec(2) += 0.5*norm2(log_m_nodes);
	}
	
	
	if(verbose)
	{
		COUT(nlvec);
		COUT(lvec);
		COUT(priors);
		COUT(pvec);
		COUT(qvec);
	}
	// COUT(nlvec);
	objfun  = sum(nlvec);
	objfun += sum(lvec);
	objfun += sum(priors);
	objfun += sum(pvec);
	objfun += sum(qvec);
	nf++;
	if(verbose)cout<<"**** Ok after calcObjectiveFunction ****"<<endl;

  }

	
FUNCTION void calcReferencePoints()
  {
  	/*
  	Purpose:  This function calculates the MSY-based reference points, and also loops
  	          over values of F and F-multipliers and calculates the equilibrium yield
  	          for each fishing gear.
  	Author: Steven Martell
  	
  	Arguments:
  		None
  	
  	NOTES:
  		- This function is based on the msyReferencePoint class object written by 
  		  Steve Martell on the Island of Maui while on Sabbatical leave from UBC.
  		- The msyReferencePoint class uses Newton-Raphson method to iteratively solve
  		  for the Fmsy values that maximize catch for each fleet. You can compare 
  		  MSY-reference points with the numerical values calculated at the end of this
  		  function.
  		- Code check: appears to find the correct value of MSY
		  in terms of maximizing ye.  Check to ensure rec-devs
		  need a bias correction term to get this right.
	
		- Modification for multiple fleets:
    	  	Need to pass a weighted average vector of selectivities
    	  	to the equilibrium routine, where the weights for each
    	  	selectivity is based on the dAllocation to each fleet.
		
	 		Perhaps as a default, assign an equal dAllocation to each
	 		fleet.  Eventually,user must specify dAllocation in 
	 		control file.  DONE
		
	 	- Use selectivity in the terminal year to calculate reference
	 	  points.  See todo, this is something that should be specified by the user.
	
		- June 8, 2012.  SJDM.  Made the following changes to this routine.
			1) changed reference points calculations to use the average
			   weight-at-age and fecundity-at-age.
			2) change equilibrium calculations to use the catch dAllocation
			   for multiple gear types. Not the average vulnerablity... this was wrong.
	
		- July 29, 2012.  SJDM Issue1.  New routine for calculating reference points
		  for multiple fleets. In this case, finds a vector of Fmsy's that simultaneously 
		  maximizes the total catch for each of the fleets respectively.  See
		  iSCAMequil_soln.R for an example.
	
		- August 1, 2012.  SJDM, In response to Issue1. A major overhaul of this routine.
		  Now using the new Msy class to calculate reference points. This greatly simplifies
		  the code in this routine and makes other routines (equilibrium) redundant.  Also
		  the new Msy class does a much better job in the case of multiple fleets.
	
		- Aug 11, 2012.
		  For the Pacific herring branch omit the get_fmsy calculations and use only the 
		  Bo calculuation for the reference points.  As there are no MSY based reference
		  points required for the descision table. 

		- May 8, 2013.
		  Starting to modify this code to allow for multiple areas, sex and stock-specific
		  reference points.  Key to this modification is the definition of a stock. For
		  the purposes of reference points, a stock is assumed to be distributed over all
		  areas, can be unisex or two sex, and can be fished by all fleets given the stock
		  exists in an area where the fishing gear operates.

		- Aug, 3-6, 2013.
		  Major effort went into revising this routine as well as the Msy class to 
		  calculate MSY-based reference points for multiple fleets and multiple sexes.  
		  I had found a significant bug in the dye calculation where I need to use the 
		  proper linear algebra to calculate the vector of dye values. This appears to 
		  be working properly and I've commented out the lines of code where I numerically
		  checked the derivatives of the catch equation.  This is a major acomplishment.

		- Mar, 2013.
		  A major new development here with the use of msy.hpp and a template class for 
		  calculating inclu-based reference points.  The user can now calculate reference
		  points for each gear based on fixed allocation, and optimum allocations based
		  on relative differences in selectivities among the gears landing fish. Uses the
		  name space "rfp".

   	PSEUDOCODE: 
   		(1) : Construct array of selectivities (potentially sex based log_sel)
   		(2) : Construct arrays of d3_wt_avg and d3_wt_mat for reference years.
	  	(3) : Come up with a reasonable guess for fmsy for each gear in nfleet.
	  	(4) : Instantiate an Msy class object and get_fmsy.
	  	(5) : Use Msy object to get reference points.

		
	slx::Selex<dvar_vector> * ptr;  //Pointer to Selex base class
  ptr = new slx::LogisticCurve<dvar_vector,dvariable>(mu,sd);
  log_sel = ptr->logSelectivity(age);
  delete ptr;

  	TODO list:
  	[ ] - allow user to specify which selectivity years are used in reference point
  	      calculations. This should probably be done in the projection File Control.
  	*/
	int kk,ig;
	
	

	// | (1) : Matrix of selectivities for directed fisheries.
	// |     : log_sel(gear)(n_ags)(year)(age)
	// |     : ensure dAllocation sums to 1.
	dvector d_ak(1,nfleet);
	d3_array  d_V(1,n_ags,1,nfleet,sage,nage);
	dvar3_array  dvar_V(1,n_ags,1,nfleet,sage,nage);
	for(k=1;k<=nfleet;k++)
	{
		kk      = nFleetIndex(k);
		d_ak(k) = dAllocation(kk);
		for(ig=1;ig<=n_ags;ig++)
		{
			d_V(ig)(k) = value( exp(log_sel(kk)(ig)(nyr)) );
			dvar_V(ig)(k) =( exp(log_sel(kk)(ig)(nyr)) );

		}
	}
	d_ak /= sum(d_ak);

	// | (2) : Average weight and mature spawning biomass for reference years
	// |     : dWt_bar(1,n_ags,sage,nage)
	dmatrix fa_bar(1,n_ags,sage,nage);
	dmatrix  M_bar(1,n_ags,sage,nage);
	for(ig=1;ig<=n_ags;ig++)
	{
		fa_bar(ig) = elem_prod(dWt_bar(ig),ma(ig));
		M_bar(ig)  = colsum(value(M(ig).sub(pf_cntrl(3),pf_cntrl(4))));
		M_bar(ig) /= pf_cntrl(4)-pf_cntrl(3)+1;	
	}
	
	// | (3) : Initial guess for fmsy for each fleet
	// |     : set fmsy = 2/3 of M divided by the number of fleets
	fmsy.initialize();
	fall.initialize();
	msy.initialize();
	bmsy.initialize();

	dvar_vector dftry(1,nfleet);
	dftry  = 0.6/nfleet * mean(M_bar);
	
	// | (4) : Instantiate msy class for each stock
	for(g=1;g<=ngroup;g++)
	{
		double d_rho = d_iscamCntrl(13);

		dvector d_mbar = M_bar(g);
		dvector   d_wa = dWt_bar(g);
		dvector   d_fa = fa_bar(g);

		//Pointer to the base class
		//rfp::referencePoints<dvariable,dvar_vector,dvar_matrix> * pMSY; 
		//pMSY = new rfp::msy<dvariable,dvar_vector,dvar_matrix,dvar3_array>
		//(ro(g),steepness(g),d_rho,M_bar,dWt_bar,fa_bar,dvar_V);
		//dvar_vector dfmsy = pMSY->getFmsy(dftry);
		//delete pMSY;
		

		cout<<"Initial Fe "<<dftry<<endl;
		rfp::msy<dvariable,dvar_vector,dvar_matrix,dvar3_array> 
		c_MSY(ro(g),steepness(g),d_rho,M_bar,dWt_bar,fa_bar,dvar_V);

		dvar_vector dfmsy = c_MSY.getFmsy(dftry,d_ak);
		bo  = c_MSY.getBo();
		dvariable dbmsy = c_MSY.getBmsy();
		dvar_vector dmsy = c_MSY.getMsy();
		bmsy(g) = value(dbmsy);
		msy(g)  = value(dmsy);
		fmsy(g) = value(dfmsy);
		c_MSY.print();

		
	}


	// Data-type version of MSY-based reference points.
	for( ig = 1; ig <= n_ags; ig++ )
	{
		fa_bar(ig) = elem_prod(dWt_bar(ig),ma(ig));
		M_bar(ig)  = colsum(value(M(ig).sub(pf_cntrl(3),pf_cntrl(4))));
		M_bar(ig) /= pf_cntrl(4)-pf_cntrl(3)+1;	
	}
	
	for( g = 1; g <= ngroup; g++ )
	{
		double d_ro  = value(ro(g));
		double d_h   = value(steepness(g));
		double d_rho = d_iscamCntrl(13);
		
		rfp::msy<double,dvector,dmatrix,d3_array>
		c_dMSY(d_ro,d_h,d_rho,M_bar,dWt_bar,fa_bar,d_V);
		fmsy(g) = c_dMSY.getFmsy(value(dftry));
		bo = c_dMSY.getBo();
		bmsy(g) = c_dMSY.getBmsy();
		msy(g)  = c_dMSY.getMsy();
		c_dMSY.print();
		dvector finit(1,nfleet);
		finit=fmsy(g);
		c_dMSY.checkDerivatives(finit);
		//cout<<"group \t"<<g<<endl;
		//exit(1);


		// Msy c_msy(d_ro,d_h,M_bar,d_rho,dWt_bar,fa_bar,&d_V);
		// fmsy(g) = 0.1;
		// c_msy.get_fmsy(fmsy(g));
		// bo = c_msy.getBo();
		// bmsy(g) = c_msy.getBmsy();
		// msy(g) = c_msy.getMsy();
		// cout<<"Old Msy class"<<endl;
		// c_msy.print();
	}

	if(verbose)cout<<"**** Ok after calcReferencePoints ****"<<endl;
  }

  /**
   * This is a simple test routine for comparing the MSY class output to the 
   * MSF.xlsx spreadsheet that was used to develop the multiple fleet msy 
   * method.  Its a permanent feature of the iscam code for testing.
   */	
FUNCTION void testMSYxls()

	double ro = 1.0;
	double steepness = 0.75;
	double d_rho = 0.0;
	dmatrix m_bar(1,1,1,20);
	m_bar = 0.30;
	dmatrix dWt_bar(1,1,1,20);
	dWt_bar(1).fill("{0.005956243,0.035832542,0.091848839,0.166984708,0.252580458,0.341247502,0.427643719,0.508367311,0.581557922,0.646462315,0.703062177,0.751788795,0.793319224,0.828438536,0.857951642,0.882630331,0.903184345,0.920248191,0.934377843,0.946053327}");
	dmatrix fa_bar(1,1,1,20);
	fa_bar(1).fill("{0,0,0,0,0.252580458,0.341247502,0.427643719,0.508367311,0.581557922,0.646462315,0.703062177,0.751788795,0.793319224,0.828438536,0.857951642,0.882630331,0.903184345,0.920248191,0.934377843,0.946053327}");
	d3_array dvar_V(1,1,1,2,1,20);
	dvar_V(1)(1).fill("{0.001271016,0.034445196,0.5,0.965554804,0.998728984,0.999954602,0.99999838,0.999999942,0.999999998,1,1,1,1,1,1,1,1,1,1,1}");
	dvar_V(1)(2).fill("{0.000552779,0.006692851,0.07585818,0.5,0.92414182,0.993307149,0.999447221,0.999954602,0.999996273,0.999999694,0.999999975,0.999999998,1,1,1,1,1,1,1,1}");
	//dvar_V(1)(2).fill("{0.000189406,0.000789866,0.003287661,0.013576917,0.054313266,0.19332137,0.5,0.80667863,0.945686734,0.986423083,0.996712339,0.999210134,0.999810594,0.999954602,0.99998912,0.999997393,0.999999375,0.99999985,0.999999964,0.999999991}");

	dvector dftry(1,2);
	dftry = 0.1 ;
	cout<<"Initial Fe "<<dftry<<endl;
	rfp::msy<double,dvector,dmatrix,d3_array> 
	c_MSY(ro,steepness,d_rho,m_bar,dWt_bar,fa_bar,dvar_V);
	dvector dfmsy = c_MSY.getFmsy(dftry);
	cout<<"Fmsy = "<<dfmsy<<endl;


	dvector ak(1,2);
	ak = 0.3;
	ak(2) = 1-ak(1);
	rfp::msy<double,dvector,dmatrix,d3_array>
	c_MSYk(ro,steepness,d_rho,m_bar,dWt_bar,fa_bar,dvar_V);
	dvector dkmsy = c_MSYk.getFmsy(dftry,ak);
	cout<<"Fmsy_k ="<<dkmsy<<endl;

	c_MSYk.print();

	dvector akmsy = c_MSYk.getFmsy(dftry);
	c_MSYk.print();




	/**
	 * @brief Return annual exploiation rates
	 * @details The exploitatoin rate is defined as the total 
	 * catch in weight for all gear types combined, divided by the total
	 * biomass.  ut = ct / bt
	 * @return a vector of the total exploitation rates.
	 */
FUNCTION dvector getExploitationRate()
	int i,ig;
	dvector ut(syr,nyr);
	dvector bt(syr,nyr);
	dvector ct(syr,nyr);
	ut.initialize();
	bt.initialize();
	ct.initialize();

	// Compute total biomass (bt)
	for( i = syr; i <= nyr; i++ )
	{
		for( ig = 1; ig <= n_ags; ig++ )
		{
			bt(i) += value(N(ig)(i)) * d3_wt_avg(ig)(i);
		}
	}

	// Compute total catch mortality (ct)
	for(i = 1; i<= nCtNobs; i++)
	{
		int iyr  = dCatchData(i)(1);
		if (iyr < syr) continue;
		if (iyr > nyr) continue;
		ct(iyr) += dCatchData(i)(7);
	}
	
	// exploitatoin rate
	ut = elem_div(ct,bt);
	return(ut);
	
  	/**
  	Purpose:  This routine gets called from the PRELIMINARY_CALCS_SECTION if the 
  	          user has specified the -sim command line option.  The random seed
  	          is specifed at the command line.

  	Author: Steven Martell
  	
  	Arguments:
  		seed -> a random seed for generating a unique, repeatable, sequence of 
  		        random numbers to be used as observation and process errors.
  	
  	NOTES:
		- This routine will over-write the observations in memory
		  with simulated data, where the true parameter values are
		  the initial values.  Change the standard deviations of the 
		  random number vectors epsilon (observation error) or 
 		  recruitment devs wt (process error).
 		- At the end of DATA_SECTION nyrs is modified by retro_yrs if -retro.
 		- Add back the retro_yrs to ensure same random number sequence for 
		  observation errors.
 
 	PSUEDOCODE:
 		1)  calculate selectivities to be used in the simulations.
 		2)  calculate mortality rates (M), F is conditioned on catch.
 		3)  generate random numbers for observation & process errors.
 		4)  calculate survivorship and stock-recruitment pars based on average M & fec.
 		5)  initialize state variables.
 		6)  population dynamics with F conditioned on catch.
 		7)  compute catch-at-age samples.
 		8)  compute total catch.
 		9)  compute the relative abundance indices.
 		10) rewrite empitical weight at age matrix.
 		11) write simulated data to file.

  	TODO list:
	[?] - March 9, 2013.  Fix simulation model to generate consistent data when 
		  doing retrospective analyses on simulated datasets.
	[ ] - TODO: Stock-Recruitment model.
	[ ] - TODO: switch statement for catch-type to get Fishing mortality rate.
  	[ ] 
  	*/
FUNCTION void simulationModel(const long& seed)
  {
	cout<<global_parfile<<endl;
	bool pinfile = 0;
	cout<<"___________________________________________________\n"<<endl;
	cout<<"  **Implementing Simulation--Estimation trial**    "<<endl;
	cout<<"___________________________________________________"<<endl;
	//if(norm(log_rec_devs)!=0)
	if( global_parfile )
	{
		cout<<"\tUsing pin file for simulation"<<endl;
		pinfile = 1;
	}
	cout<<"\tRandom Seed No.:\t"<< rseed<<endl;
	cout<<"\tNumber of retrospective years: "<<retro_yrs<<endl;
	cout<<"___________________________________________________\n"<<endl;
	
	

	int ii,ig,ih;
	// |---------------------------------------------------------------------------------|
	// | 1) SELECTIVITY
	// |---------------------------------------------------------------------------------|
	// |
    calcSelectivities(isel_type);
    

    // |---------------------------------------------------------------------------------|
    // | 2) MORTALITY
    // |---------------------------------------------------------------------------------|
    // | - NOTE only natural mortality is computed at this time.
    // | [ ] - add simulated random-walk in natural mortality rate here.
    // |
    calcTotalMortality();
    F.initialize();
    Z.initialize();
    S.initialize();



    // |---------------------------------------------------------------------------------|
    // | 3) GENERATE RANDOM NUMBERS
    // |---------------------------------------------------------------------------------|
    // | - epsilon -> Observation errors
    // | - rec_dev -> Process errors
    // | - init_rec_dev
    // | [ ] - add other required random numbers if necessary.
    // |
	random_number_generator rng(seed);
	dmatrix      epsilon(1,nItNobs,1,n_it_nobs);
	dmatrix      rec_dev(1,n_ag,syr,nyr+retro_yrs);
	dmatrix init_rec_dev(1,n_ag,sage+1,nage);
	dvector      eta(1,nCtNobs);
    

	epsilon.fill_randn(rng);
	rec_dev.fill_randn(rng);
	init_rec_dev.fill_randn(rng);
	eta.fill_randn(rng);

    // | Scale survey observation errors
    double std;
    for(k=1;k<=nItNobs;k++)
    {
    	for(i=1;i<=n_it_nobs(k);i++)
    	{
    		std = 1.0e3;
    		if( it_se(k,i)>0 )
    		{
    			std = (it_se(k,i));
    		}
    		epsilon(k,i) = epsilon(k,i)*std - 0.5*std*std;
    	}
    }

    // | Scale process errors
    for(ih=1;ih<=n_ag;ih++)
    {
		std              = value(sigma_r(1));
		rec_dev(ih)      = rec_dev(ih) * std - 0.5*std*std;
		init_rec_dev(ih) = init_rec_dev(ih)*std - 0.5*std*std;
    }

    // | Scale total catch errors
    std = d_iscamCntrl(4);
    for(ii=1;ii<=nCtNobs;ii++)
    {
    	eta(ii) = eta(ii)* std  - 0.5*std*std;
    }

    // |---------------------------------------------------------------------------------|
    // | 4) SURVIVORSHIP & STOCK-RECRUITMENT PARAMETERS BASED ON AVERAGE M & FECUNDITY
    // |---------------------------------------------------------------------------------|
    // | -> Loop over each group/stock and compute survivorship, phib, so and beta.
    // | - fa is the average mature weight-at-age
    // |
    double phib;
    dvector ma(sage,nage);
    dvector fa(sage,nage);
    dvector lx(sage,nage);
    dvector lw(sage,nage);

    for(g=1;g<=ngroup;g++)
    {
    	lx.initialize();
		lw.initialize();
		lx(sage) = 1.0;
		lw(sage) = 1.0;
		phib = 0;
		for(f=1;f<=narea;f++)
		{
			for(h=1;h<=nsex;h++)
			{
				ig = pntr_ags(f,g,h);
				for(j=sage;j<=nage;j++)
				{
					ma(j) = mean( trans(value(M(ig)))(j)  );
					fa(j) = mean( trans(d3_wt_mat(ig))(j) );
					if(j>sage)
					{
						lx(j) = lx(j-1) * exp(-ma(j-1));
					}
					lw(j) = lx(j) * exp( -ma(j)*d_iscamCntrl(13) );
				}
				lx(nage) /= 1.0 - exp(-ma(nage));
				lw(nage) /= 1.0 - exp(-ma(nage));

				phib += 1./(narea*nsex) * lw * fa;
			}
		}
		so(g)  = kappa(g)/phib;
		sbo(g) = ro(g) * phib;
		switch(int(d_iscamCntrl(2)))
		{
			case 1:
				beta(g) = (kappa(g)-1.0)/sbo(g);
			break;
			case 2:
				beta(g) = log(kappa(g))/sbo(g);
			break;
		}
    }


   // |---------------------------------------------------------------------------------|
   // | 5) INITIALIZE STATE VARIABLES
   // |---------------------------------------------------------------------------------|
   // |
	N.initialize();
	for(ig=1;ig<=n_ags;ig++)
	{
		dvector tr(sage,nage);
		f  = n_area(ig);
		g  = n_group(ig);
		ih = pntr_ag(f,g);
		
		lx.initialize();
		lx(sage) = 1.0;
		for(j=sage;j<nage;j++)
		{
			lx(j+1) = lx(j) * exp(-value(M(ig)(syr)(j)));
		}
		lx(nage) /= 1.0 - exp(-value(M(ig)(syr)(nage)));
		if( d_iscamCntrl(5) )
		{
			tr = log( value(ro(g)) ) + log(lx);
		}
		else if( !d_iscamCntrl(5) )
		{
			tr(sage)        = value(log_avgrec(ih)+rec_dev(ih)(syr));;
			tr(sage+1,nage) = value(log_recinit(ih)+init_rec_dev(ih));
			tr(sage+1,nage) = tr(sage+1,nage)+log(lx(sage+1,nage));
		}
		N(ig)(syr)(sage,nage) = 1./nsex * exp(tr);
		log_rt(ih)(syr-nage+sage,syr) = tr.shift(syr-nage+sage);

		for(i=syr+1;i<=nyr;i++)
		{
			log_rt(ih)(i) = (log_avgrec(ih)+rec_dev(ih)(i));
			N(ig)(i,sage) = 1./nsex * exp( log_rt(ih)(i) );
		}
		N(ig)(nyr+1,sage) = 1./nsex * exp(log_avgrec(ih));
	}

	// |---------------------------------------------------------------------------------|
	// | 6) POPULATION DYNAMICS WITH F CONDITIONED ON OBSERVED CATCH
	// |---------------------------------------------------------------------------------|
	// | - va  -> matrix of fisheries selectivity coefficients.
	// | - [ ] TODO: switch statement for catch-type to get Fishing mortality rate.
	// | - [ ] TODO: Stock-Recruitment model (must loop over area sex for each group).
	// | - bug! ft is a global variable used in calcCatchAtAge and calcTotalCatch. FIXED
	// | - [ ] TODO: fishing mortality rate with sex ratio of catch is unknown and assume
	// |             the same F value for both male and females.
	dmatrix va(1,ngear,sage,nage);
	dmatrix zt(syr,nyr,sage,nage);
	dmatrix st(syr,nyr,sage,nage);
	BaranovCatchEquation cBaranov;
	for(ig=1;ig<=n_ags;ig++)
	{
		dmatrix tmp_ft(syr,nyr,1,ngear);

		for(i=syr;i<=nyr;i++)
		{
			dvector ba = elem_prod(value(N(ig)(i)),d3_wt_avg(ig)(i));
			dvector ct = d3_Ct(ig)(i);

			// | Selectivity modifications if necessary
			for(k=1;k<=ngear;k++)
			{
				va(k) = exp(value(log_sel(k)(ig)(i)));
				if( d_iscamCntrl(15) == 1 && dAllocation(k) > 0 )
				{
					va(k)             = ifdSelex(va(k),ba,0.25);
					log_sel(k)(ig)(i) = log(va(k));
					// dlog_sel(k)(i) = log(va(k));
				}
			}

			// | [ ] TODO switch statement for catch_type to determine F.
			tmp_ft(i) = cBaranov.getFishingMortality(ct, value(M(ig)(i)), va, value(N(ig)(i)),d3_wt_avg(ig)(i));
			
			zt(i) = value(M(ig)(i));
			for(k=1;k<=ngear;k++)
			{
				ft(ig)(k)(i) = tmp_ft(i,k);
				F(ig)(i) += tmp_ft(i,k) * va(k);
				zt(i) += tmp_ft(i,k) * va(k);
			}
			st(i) = exp(-zt(i));
			Z(ig)(i) = M(ig)(i) + F(ig)(i);
			S(ig)(i) = exp(-Z(ig)(i));

			// | [ ] TODO: Stock-Recruitment model
			// | [ ] TODO: Add autocorrelation.

			if( !pinfile ) COUT("Add stock recruitment Model")
			/* 
			sbt(ig)(i) = (elem_prod(N(ig)(i),exp(-zt(i)*d_iscamCntrl(13)))*d3_wt_mat(ig)(i));
			if(i>=syr+sage-1 && !pinfile)
			{
				double rt,et;
				et = value(sbt(ig)(i-sage+1));
				if(d_iscamCntrl(2)==1)
				{
					rt = value(so(g)*et/(1.+beta(g)*et));
				}
				else
				{
					rt = value(so(g)*et*exp(-beta(g)*et));
				}
				N(ig)(i)(sage) = rt * exp(rec_dev(ih)(i)-0.5*tau*tau);
			}
			*/

			// | Update state variables
			N(ig)(i+1)(sage+1,nage) =++ elem_prod(N(ig)(i)(sage,nage-1),st(i)(sage,nage-1));
			N(ig)(i+1)(nage) += N(ig)(i)(nage)*st(i)(nage);
		}
	}


	// |---------------------------------------------------------------------------------|
	// | 7) CATCH-AT-AGE
	// |---------------------------------------------------------------------------------|
	// | - A is the matrix of observed catch-age data.
	// | - A_hat is the predicted matrix from which to draw samples.
	// |
	int kk,aa,AA;
	double age_tau = value(sig(1));
	
	calcComposition();

	for(kk=1;kk<=nAgears;kk++)
	{
		aa = n_A_sage(kk);
		AA = n_A_nage(kk);
		dvector pa(aa,AA);
		for(ii=1;ii<=n_A_nobs(kk);ii++)
		{
			pa = value(A_hat(kk)(ii));
			d3_A(kk)(ii)(aa,AA)=rmvlogistic(pa,age_tau,i+seed);
		}
	}
	
	// |---------------------------------------------------------------------------------|
	// | 8) TOTAL CATCH
	// |---------------------------------------------------------------------------------|
	// | - dCatchData is the matrix of observations
	// | - need to over-write the d3_Ct with the new errors.
	
	calcTotalCatch();
	d3_Ct.initialize();
	for(ii=1;ii<=nCtNobs;ii++)
	{
		dCatchData(ii,7) = value(ct(ii)) * exp(eta(ii));
		i = dCatchData(ii)(1);
		k = dCatchData(ii)(2);
		f = dCatchData(ii)(3);
		g = dCatchData(ii)(4);
		h = dCatchData(ii)(5);
		if( h==0 )
		{
			for(h=1;h<=nsex;h++)
			{
				ig = pntr_ags(f,g,h);
				d3_Ct(ig)(i)(k) = 1./nsex*dCatchData(ii)(7);
			}
		}
		else
		{
			ig = pntr_ags(f,g,h);
			d3_Ct(ig)(i)(k) = dCatchData(ii)(7);
		} 
	}
	// cout<<d3_Ct(1)<<endl;


	// |---------------------------------------------------------------------------------|
	// | 9) RELATIVE ABUNDANCE INDICES
	// |---------------------------------------------------------------------------------|
	// | - d3_survey_data is the matrix of input data.
	// |

	calcSurveyObservations();
	for(kk=1;kk<=nItNobs;kk++)
	{
		for(ii=1;ii<=n_it_nobs(kk);ii++)
		{
			d3_survey_data(kk)(ii)(2) *= exp(epsilon(kk)(ii));	
		}
	}
	
	// |---------------------------------------------------------------------------------|
	// | 10) Empirical weight at age
	// |---------------------------------------------------------------------------------|
	// | 

		for(int ii=1; ii<=nWtTab; ii++)
		{
			if(nWtNobs(ii) > 0 )
			{
				d3_inp_wt_avg(ii,1,sage-5) = d3_inp_wt_avg(ii,1,sage-5)*projwt(ii);
			}
		}
		cout<< d3_inp_wt_avg(1)(1)(sage-5,nage) <<endl;

	// |---------------------------------------------------------------------------------|
	// | 11) WRITE SIMULATED DATA TO FILE
	// |---------------------------------------------------------------------------------|
	// |
	writeSimulatedDataFile();

	
// 	calcReferencePoints();
// 	//cout<<"	OK after reference points\n"<<fmsy<<endl;
// 	//exit(1);
// 	//	REPORT(fmsy);
// 	//	REPORT(msy);
// 	//	REPORT(bmsy);
	
	
// 	cout<<"___________________________________________________"<<endl;
// 	ofstream ofs("iscam.sim");
// 	ofs<<"fmsy\n"<<fmsy<<endl;
// 	ofs<<"msy\n"<<msy<<endl;
// 	ofs<<"bmsy\n"<<bmsy<<endl;
// 	ofs<<"bo\n"<<bo<<endl;
// 	ofs<<"va\n"<<va<<endl;
// 	ofs<<"sbt\n"<<sbt<<endl;//<<rowsum(elem_prod(N,fec))<<endl;
// 	ofs<<"log_rec_devs\n"<<log_rec_devs<<endl;
// 	ofs<<"rt\n"<<rt<<endl;
// 	ofs<<"ct\n"<<obs_ct<<endl;
// 	ofs<<"ft\n"<<trans(ft)<<endl;
// 	//ofs<<"ut\n"<<elem_div(colsum(obs_ct),N.sub(syr,nyr)*wa)<<endl;
// 	ofs<<"iyr\n"<<iyr<<endl;
// 	ofs<<"it\n"<<it<<endl;
// 	ofs<<"N\n"<<N<<endl;
// 	ofs<<"A\n"<<A<<endl;
// 	ofs<<"dlog_sel\n"<<dlog_sel<<endl;
// 	cout<<"  -- Simuation results written to iscam.sim --\n";
// 	cout<<"___________________________________________________"<<endl;
	
// 	//cout<<N<<endl;
// 	//exit(1);
  }





  	/**
  	Purpose:  This function writes a simulated data file based on the simulation
  		  model output when the user specifies the -sim option.  This is only
  	      necessary if the user wishes to perform a retrospecrtive analysis on
  	      simulated data. 

  	Author: Steven Martell
  	
  	Arguments:
  	\param	seed -> the random number seed that is concatenated into the file name.
  	
  	NOTES:
  		
  	
  	TODO list:
  	[ ] 
  	*/
FUNCTION writeSimulatedDataFile
  {
  	adstring sim_datafile_name = "Simulated_Data_"+str(rseed)+".dat";
  	ofstream dfs(sim_datafile_name);
  	dfs<<"#Model dimensions"<<endl;
  	dfs<< narea 		<<endl;
  	dfs<< ngroup		<<endl;
  	dfs<< nsex			<<endl;
  	dfs<< syr   		<<endl;
  	dfs<< nyr   		<<endl;
  	dfs<< sage  		<<endl;
  	dfs<< nage  		<<endl;
  	dfs<< ngear 		<<endl;
 
  	dfs<<"#Allocation"	<<endl;
  	dfs<< dAllocation 	<<endl;
  	
  	dfs<<"#Age-schedule and population parameters"<<endl;
  	dfs<< d_linf  			<<endl;
  	dfs<< d_vonbk  			<<endl;
  	dfs<< d_to  			<<endl;
  	dfs<< d_a  				<<endl;
  	dfs<< d_b  				<<endl;
  	dfs<< d_ah  			<<endl;
  	dfs<< d_gh  			<<endl;
  	dfs<< n_MAT				<<endl;
	dfs<< d_maturityVector <<endl;

  	dfs<<"#Observed catch data"<<endl;
  	dfs<< nCtNobs 		<<endl;
  	dfs<< dCatchData    <<endl;

  	dfs<<"#Abundance indices"	<<endl;
  	dfs<< nItNobs 					<<endl;
  	dfs<< n_it_nobs 				<<endl;
  	dfs<< n_survey_type 			<<endl;
  	dfs<< d3_survey_data 			<<endl;

  	dfs<<"#Age composition"		<<endl;
  	dfs<< nAgears				<<endl;
  	dfs<< n_A_nobs				<<endl;
  	dfs<< n_A_sage				<<endl;
  	dfs<< n_A_nage				<<endl;
  	dfs<< inp_nscaler 			<<endl;
  	dfs<< d3_A					<<endl;

  	dfs<<"#Empirical weight-at-age data"	<<endl;
  	dfs<< nWtTab 				<<endl;
  	dfs<< nWtNobs				<<endl;
	dfs<< d3_inp_wt_avg			<<endl; // not sure if this shoud be d3_inp_wt_avg, and how this would affect simDatfile 

	dfs<<"#EOF"	<<endl;
	dfs<< 999	<<endl;
	
	// | END OF WRITING SIMULATED DATAFILE.
  }


FUNCTION TAC_input
	{
	/**
  	Purpose:  This function writes out input variables that would be used in the 
  	calculation of catch limits in the lagrangian model MSE

  	Author: Catarina Wor
  	
  	Arguments:
  	\param	seed -> the random number seed that is concatenated into the file name.
  	
  	NOTES:
  		
  	
  	TODO list:
  	[ ] 
  	*/
	
	ofstream bfs("/Users/catarinawor/Documents/Lagrangian/OM/TAC_input.dat");
	bfs<<"#fspr" << endl << fspr <<endl;

	// 4darray log_sel(1,ngear,1,n_ags,syr,nyr,sage,nage);
	bfs<<"# log_selectivity"<<endl;
	for(int k = 1; k <= ngear; k++ )	
	{
		for(int ig = 1; ig <= n_ags; ig++){
			bfs<<mfexp(log_sel(k)(ig)(nyr))<<endl;
		}
	}

	// 3darray N(1,n_ags,syr,nyr,sage,nage);
	bfs<<"# Numbers at age"<<endl;
	for(int ig = 1; ig <= n_ags; ig++){
			bfs<<N(ig)(nyr)(sage,nage)<<endl;
	}
	
	bfs<<"#Bo" << endl << bo<<endl;
	
	bfs<<"#ytB" << endl;
	for(int g = 1; g <= ngroup; g++){
		bfs<<bt(g)(nyr)<<endl;
	}

	

	//ofs<<"#seltotal" << endl << seltotal(nyr)(sage,nage) <<endl;	
	//ofs<<"#yNage" << endl << yNage(nyr)(sage,nage) <<endl;	
	//ofs<<"#Bo" << endl << Bo<<endl;
	//ofs<<"#ytB" << endl << ytB(nyr) <<endl;
	}







  	
FUNCTION dvector ifdSelex(const dvector& va, const dvector& ba, const double& mpow)
  {

  	dvector pa(sage,nage);

  	pa = (elem_prod(va,pow(ba,mpow)));
  	pa = pa/sum(pa);
  	pa = exp( log(pa) - log(mean(pa)) );
  	return (pa);
  }

REPORT_SECTION
  	dvector ut = getExploitationRate();
  	

	if(verbose)cout<<"Start of Report Section..."<<endl;
	report<<DataFile<<endl;
	report<<ControlFile<<endl;
	report<<ProjectFileControl<<endl;
	REPORT(objfun);
	REPORT(nlvec);
	REPORT(ro);
	dvector rbar=value(exp(log_avgrec));
	REPORT(rbar);
	dvector rinit=value(exp(log_recinit));
	REPORT(rinit);
	REPORT(sbo);
	REPORT(kappa);
	dvector steepness=value(theta(2));
	REPORT(steepness);
	REPORT(m);
	REPORT(phib);
	// double tau = value(sqrt(1.-rho)*varphi);
	// double sig = value(sqrt(rho)*varphi);
	
	REPORT(sigma_r);
	REPORT(sig);
	REPORT(age_tau2);
	
	// |---------------------------------------------------------------------------------|
	// | MODEL DIMENSIONS & AGE-SCHEDULE INFORMATION ON GROWTH AND MATURITY
	// |---------------------------------------------------------------------------------|
	// |
	REPORT(narea);
	REPORT(ngroup);
	REPORT(nsex);
	REPORT(syr);
	REPORT(nyr);
	REPORT(sage);
	REPORT(nage);
	REPORT(ngear);

	ivector yr(syr,nyr);
	ivector yrs(syr,nyr+1);
	yr.fill_seqadd(syr,1); 
	yrs.fill_seqadd(syr,1); 
	REPORT(yr);
	REPORT(yrs);
	// REPORT(iyr);  //DEPRECATE, old survey years
	REPORT(age);
	REPORT(la);
	REPORT(wa);
	REPORT(ma);

	// |---------------------------------------------------------------------------------|
	// | OBSERVED AND PREDICTED DATA AND RESIDUALS
	// |---------------------------------------------------------------------------------|
	// | - Catch data
	// | - Survey data
	// | - Age composition data
	// | - Empirical weight-at-age data
	REPORT(dCatchData);
	REPORT(ct);
	REPORT(eta);

	REPORT(q);
	REPORT(qt);
	REPORT(d3_survey_data);
	REPORT(it_hat);
	REPORT(it_se);
	REPORT(epsilon);

	if(n_A_nobs(nAgears) > 0)
	{
		REPORT(n_A_sage);
		REPORT(n_A_nage);

		for(k = 1; k<=nAgears; k++)
		{
			adstring lbl = "d3_A"+str(k);
			report<<lbl<<endl<<d3_A(k)<<endl;
		}
		for(k = 1; k<=nAgears; k++)
		{
			adstring lbl = "A_hat"+str(k);
			report<<lbl<<endl<<A_hat(k)<<endl;
		}
		for(k = 1; k<=nAgears; k++)
		{
			adstring lbl = "A_nu"+str(k);
			report<<lbl<<endl<<A_nu(k)<<endl;
		}


		// Deprecate in version 2.0
		REPORT(d3_A);
		REPORT(A_hat);
		REPORT(A_nu);




		/// The following is a total hack job to get the effective sample size
		/// for the multinomial distributions.

		// FIXED the retrospective bug here near line 4507 (if iyr<=nyr)
		report<<"Neff"<<endl;
		dvector nscaler(1,nAgears);
		nscaler.initialize();
		for(k = 1; k<=nAgears; k++)
		{

			if( int(nCompLikelihood(k)) )
			{
				int naa=0;
				int iyr;
				//retrospective counter
				for(i=1;i<=n_A_nobs(k);i++)
				{
					iyr = d3_A(k)(i)(n_A_sage(k)-6);	//index for year
					if(iyr<=nyr) naa++; else continue;
				}
				
				dmatrix     O = trans(trans(d3_A_obs(k)).sub(n_A_sage(k),n_A_nage(k))).sub(1,naa);
				dvar_matrix P = trans(trans(A_hat(k)).sub(n_A_sage(k),n_A_nage(k))).sub(1,naa);
				
				for(j = 1; j<= naa; j++)
				{
					double effectiveN = neff(O(j)/sum(O(j)),P(j));
					report<<sum(O(j))<<"\t"<<effectiveN<<endl;
					nscaler(k) += effectiveN;
				}	
				
				nscaler(k) /= naa;
			}
		}
		REPORT(nscaler);
	}

	// d3_wt_avg(1,n_ags,syr,nyr+1,sage,nage);
	adstring tt = "\t";
	REPORT(xxinp_wt_avg);
	REPORT(dWt_bar);
	// REPORT(d3_wt_avg);
	REPORT(d3_wt_mat);
	REPORT(d3_wt_dev);

	report<<"d3_wt_avg"<<endl;
	for(int ig=1;ig<=n_ags;ig++)
	{
		f = n_area(ig);
		g = n_group(ig);
		h = n_sex(ig);
		
		for(i=syr;i<=nyr;i++)
		{
			//year area stock sex |age columns (sage, nage) of weight at age data |
			report<<i<<tt;
			report<<f<<tt;
			report<<g<<tt;
			report<<h<<tt;
			report<<d3_wt_avg(ig)(i)<<endl;
		}
	
	}


	// |---------------------------------------------------------------------------------|
	// | SELECTIVITIES (4darray)
	// |---------------------------------------------------------------------------------|
	// |
	report<<"log_sel"<<endl;
	for(k=1;k<=ngear;k++)
	{
		for(int ig=1;ig<=n_ags;ig++)
		{
			int h = n_sex(ig);
			int f = n_area(ig);
			int g = n_group(ig);
			for(i=syr;i<=nyr;i++)
			{
				report<<k<<"\t"<<f<<"\t"<<g<<"\t"<<h<<"\t"<<i<<"\t";
				report<<log_sel(k)(ig)(i)<<endl;	
			}
		}
	}
	// |---------------------------------------------------------------------------------|
	// | MORTALITY
	// |---------------------------------------------------------------------------------|
	// |
	// REPORT(ft);
	//REPORT(ft_count);
	REPORT(ft_count);
	REPORT(ut);
	report<<"ft"<<endl;
	for(int ig = 1; ig <= n_ags; ig++ )
	{
		report<<ft(ig)<<endl;
	}
	REPORT(M);
	REPORT(F);
	REPORT(Z);

	// |---------------------------------------------------------------------------------|
	// | STOCK-RECRUITMENT
	// |---------------------------------------------------------------------------------|
	// |
	int rectype=int(d_iscamCntrl(2));
	REPORT(rectype);
	REPORT(so);
	REPORT(beta);
	REPORT(sbt);
	REPORT(bt);
	REPORT(rt);
	REPORT(delta);
	
	dmatrix rep_rt = value( exp(trans(trans(log_rt).sub(syr,nyr))) );
	for(int ig = 1; ig <= n_ag; ig++ )
	{
		rep_rt(ig)(syr) = value( exp( log_rt(ig)(syr-nage+sage) ) );
	}
	REPORT(rep_rt);

	// |---------------------------------------------------------------------------------|
	// | ABUNDANCE IN NUMBERS `
	// |---------------------------------------------------------------------------------|
	// |
	REPORT(N);

	// |---------------------------------------------------------------------------------|
	// | MSY-BASED REFERENCE POINTS
	// |---------------------------------------------------------------------------------|
	// |
	if( last_phase() )
	{
		cout<<"Calculating MSY-based reference points"<<endl;
		calcReferencePoints();
		cout<<"Finished calcReferencePoints"<<endl;

		cout<<"Calculating SPR current"<<endl;
		calcSprRatio();
		cout<<"Finished calcSprRatio"<<endl;
		//exit(1);
		REPORT(bo);
		REPORT(fmsy);
		REPORT(msy);
		REPORT(bmsy);
		REPORT(spr);
		REPORT(fspr);
		//REPORT(allspr);
		//REPORT(diffspr);
		// REPORT(Umsy);
	}

	cout<<"You got to the end of the report section"<<endl;
	// |---------------------------------------------------------------------------------|
	// | OUTPUT FOR OPERATING MODEL
	// |---------------------------------------------------------------------------------|
	// | Move to final section?
	if( last_phase() )
	{
		ofstream ofs("iSCAM.res");

		ofs<<"# Bo\n"<<bo<<endl;
		ofs<<"# Fmsy\n"<<fmsy<<endl;
		ofs<<"# MSY\n"<<msy<<endl;
		ofs<<"# Bmsy\n"<<bmsy<<endl;
		ofs<<"# Sbt\n";
		for( g = 1; g <= ngroup; g++ )
		{
			ofs<<sbt(g)(nyr+1)<<"\t";
		}
		ofs<<endl;

		// projected biomass
		// The total biomass for each stock
		ofs<<"# Total biomass\n";
		for( g = 1; g <= ngroup; g++ )
		{
			ofs<<bt(g)(nyr+1)<<"\t";
		}
		ofs<<endl;

		ofs<<"# Numbers-at-age\n";
		for(int ig = 1; ig <= n_ags; ig++ )
		{
			ofs<<N(ig)(nyr+1)<<endl;
		}

		ofs<<"# Weight-at-age\n";
		for(int ig = 1; ig <= n_ags; ig++ )
		{
			ofs<<d3_wt_avg(ig)(nyr+1)<<endl;
		}		

		ofs<<"# Natural mortality-at-age\n";
		for(int ig = 1; ig <= n_ags; ig++ )
		{
			ofs<<M(ig)(nyr)<<endl;
		}		


		// 4darray log_sel(1,ngear,1,n_ags,syr,nyr,sage,nage);
		ofs<<"# log_selectivity\n";
		for(int k = 1; k <= ngear; k++ )	
		{
			for(int ig = 1; ig <= n_ags; ig++ )
			{
				ofs<<log_sel(k)(ig)(nyr)<<endl;
			}
		}
	}




	if(verbose)cout<<"END of Report Section..."<<endl;
	

	
FUNCTION generate_new_files
   {

   	ofstream rd("RUN.dat");
		rd<<NewFileName + ".dat"<<endl;
		rd<<NewFileName + ".ctl"<<endl;
		rd<<NewFileName + ".pfc"<<endl;
	system("say Luke I am your father");
	exit(1);


	#if defined __APPLE__ || defined __linux

	adstring bscmddat = "cp ../lib/iscam.dat" + NewFileName +".dat";
		system(bscmddat);

	adstring bscmdctl = "cp ../lib/iscam.ctl" + NewFileName +".ctl";
		system(bscmdctl);

	adstring bscmdpfc = "cp ../lib/iscam.PFC" + NewFileName +".pfc";
		system(bscmdpfc);	

	#endif

	#if defined _WIN32 || defined _WIN64

	adstring bscmddat = "copy ../lib/iscam.dat" + NewFileName +".dat";
		system(bscmddat);

	adstring bscmdctl = "copy ../lib/iscam.ctl" + NewFileName +".ctl";
		system(bscmdctl);

	adstring bscmdpfc = "copy ../lib/iscam.PFC" + NewFileName +".pfc";
		system(bscmdpfc);	

	#endif

  }

FUNCTION mcmc_output


	/**
	 * @brief Calculate the Spawning Potential Ratio
	 * @details This routine calcualtes the Spawning potential ratio that is 
	 * used as a proxy for the annual total mortality rate relative to the
	 * unfished conditions.
	 */

FUNCTION dvector calcEqLambda(double fbar)
	/**
	 * @brief Calculate the F that will lead to an SPR ratio (SPRcurrent/SPFunfished) equal to SPR target
	 * @details This routine require that the allocation between gears is set before the assessment model is run
	 */

	//dvector fbar(1,4001);
	//fbar.fill_seqadd(0,0.01);

	int iter,g,f,h,ig;
	dvector lambda(1,nfleet);
	dvector lamt(1,nfleet);
	dvector fk(1,nfleet);
	
	dvector 	va(sage,nage);
	dvector 	ma(sage,nage);
	dvector 	za(sage,nage);
	dvector 	sa(sage,nage);
	dvector 	oa(sage,nage);
	dvector 	fe(sage,nage);
	dvector 	fa(sage,nage);
	dvector 	lz(sage,nage);
	dvector 	lw(sage,nage);
	dvector 	lx(sage,nage);
	dvector 	fec(sage,nage);

	dmatrix 	qa(1,nfleet,sage,nage);
	dmatrix    	phik(1,ngroup,1,nfleet);

	lambda=1.0;



	for(iter=1;iter<=2;iter++)
	{

		for(g=1;g<=ngroup;g++)
		{ 
			lz.initialize();
			qa.initialize();
			
			ma.initialize();
			za.initialize();
			sa.initialize();
			oa.initialize();
			
			for(f=1;f<=narea;f++)
			{
				for(h=1;h<=nsex;h++)
				{
					ig = pntr_ags(f,g,h);	
					fa.initialize();

					for(j=sage;j<=nage;j++)
					{
						ma(j) = value(mean(trans(M(ig))(j)));
					}
					
					for(k=1;k<=nfleet;k++)
					{
						va.initialize();
						fe.initialize();
						fe = fbar * lambda(k);
						va = value(mfexp(log_sel(k)(ig)(nyr)));
						fa += fe * va;					
					}				
					za = ma + fa;
					sa = mfexp(-za);
					oa = 1.0 - sa;	

					lz(sage) = 1.0;
					
					for(j=sage+1;j<=nage;j++)
					{
						lz(j) = lz(j-1) * mfexp(-za(j-1));
					}

					lz(nage) /= 1.0 - mfexp(-za(nage));

						
					for(k=1;k<=nfleet;k++)
					{
						qa(k) = (elem_div(elem_prod(elem_prod(va, d3_wt_avg(ig)(nyr+1)),oa),za));
						//pa(k,) = elem_div(elem_prod(va,oa),za);
						phik(g,k) = lz * qa(k);
					}		
				}
			}


			lamt = elem_div(fleetAllocation, (phik(g)/sum(phik(g))));
			lambda = lamt/mean(lamt);
		}
		
	}

	fk = lambda*fbar;

	return(fk);






	 



FUNCTION calcSprRatio
	/**
	 * @brief Calculate SPR in the last year
	 * @details [long description
	 * TODO read in SPR target
	 */
	 //SPR=phi.e/phi.E
	 int g,f,h,ig,j,k,it,gg,itt;

	dvector     lx(sage,nage);
	dvector     lw(sage,nage);  
	dvector     lz(sage,nage);
	dvector     lzw(sage,nage);
	dvector 	fec(sage,nage);
	dvector 	fa(sage,nage);
	dvector 	va(sage,nage);
	dvector 	ma(sage,nage);
	dvector 	fe(1,nfleet);
	dvector 	sol(1,ngroup);


	
	dvector fbars(1,4001);
	fbars.fill_seqadd(0.000,0.001);


	int NF=size_count(fbars);

	dmatrix allspr(1,ngroup,1,NF);
	dmatrix allphie(1,ngroup,1,NF);
	dmatrix diffspr(1,ngroup,1,NF);

	for(it=1;it<=NF;it++)
	{

		phiE.initialize();
		for(g=1;g<=ngroup;g++)
		{ 
			
			lx.initialize();
			lw.initialize();
			lz.initialize();
			lzw.initialize();
		
	
			lw(sage) = 1.0;
			lx(sage) = 1.0;
			lz(sage) = 1.0;
			lzw(sage) = 1.0;

			for(f=1;f<=narea;f++)
			{
				for(h=1;h<=nsex;h++)
				{
					ig = pntr_ags(f,g,h);

					va.initialize();
					fa.initialize();

					fe = calcEqLambda(fbars(it));
					
					for(k=1;k<=nfleet;k++)
					{
						va = value(mfexp(log_sel(nFleetIndex(k))(ig)(nyr)));
						fa += fe(k) * va;
					}

					// | Step 1. average natural mortality rate at age.
					// | Step 2. calculate survivorship
					for(j=sage;j<=nage;j++)
					{
						ma(j) = value(mean(trans(M(ig))(j)));
						fec(j) = (mean(trans(d3_wt_mat(ig))(j) ));
	
						if(j > sage)
						{
							lx(j) = lx(j-1) * mfexp(-ma(j-1));
							lz(j) = lz(j-1) * mfexp(-ma(j-1)-fa(j-1));
						}
						lw(j) = lx(j) * mfexp(-ma(j)*d_iscamCntrl(13));
						lzw(j) = lz(j) * mfexp(-(ma(j)+fa(j))*d_iscamCntrl(13));
					}
					lx(nage) /= 1.0 - mfexp(-ma(nage));
					lw(nage) /= 1.0 - mfexp(-ma(nage));
					lz(nage) /= 1.0 - mfexp(-ma(nage)-fa(nage));
					lzw(nage) /= 1.0 - mfexp(-ma(nage)-fa(nage));
					
				
					// | Step 3. calculate average spawing biomass per recruit.
		
				}				
			}
			phiE(g) = 1./(narea*nsex) * lw*fec;

			allphie(g)(it) = 1./(narea*nsex) * lzw*fec;

			//cout<<"phiE(g) is "<<phiE(g)<<endl;
			//cout<<"allphie(g)(it)  is "<<allphie(g)(it) <<endl;
			
			allspr(g)(it)=value(allphie(g)(it)/phiE(g));
			//cout<<"allspr(g)(it) is "<<allspr(g)(it)<<endl;
			diffspr(g)(it) = (allspr(g)(it)-0.40)*(allspr(g)(it)-0.40); //SPR target fixed at 40% for now
			
			
		}
		
		

			
	}
	//cout<<"allspr(g)(it) is "<<allspr<<endl;
	//cout<<"diffspr(g)(it) is "<<diffspr<<endl;
	//exit(1);

	for(gg=1;gg<=ngroup;gg++)
		{	
			sol(gg)=(min(diffspr(gg)));
		}



	for(itt=1; itt<=NF; itt++)
	{

		for(gg=1;gg<=ngroup;gg++)
		{
			
			//sol(gg)=max(diffspr(gg)); 
			if(sol(gg)==diffspr(gg)(itt)){
				spr(gg) = allspr(gg)(itt);
				
				phie(gg)= allphie(gg)(itt);
				fspr(gg) = calcEqLambda(fbars(itt));
	
			} 
		}
	}

 	

		


FUNCTION void runMSE()
	cout<<"Start of runMSE"<<endl;
	

	// STRUCT FOR MODEL VARIABLES
	ModelVariables s_mv;
	s_mv.log_ro    = value( theta(1) );
	s_mv.steepness = value( theta(2) );
	s_mv.m         = value( theta(3) );
	s_mv.log_rbar  = value( theta(4) );
	s_mv.log_rinit = value( theta(5) );
	s_mv.rho       = value( theta(6) );
	s_mv.varphi    = value( theta(7) );


	// Selectivity parameters
	// BUG: jsel_npar and isel_npar are deprecated.
	d3_array log_sel_par(1,ngear,1,jsel_npar,1,isel_npar);
	d4_array d4_log_sel(1,ngear,1,n_ags,syr,nyr,sage,nage);
	for(int k = 1; k <= ngear; k++ )  //slx_nrow
	{
		log_sel_par(k) = value(sel_par(k));
		d4_log_sel(k)  = value(log_sel(k));
	}
	s_mv.d3_log_sel_par = &log_sel_par;
	s_mv.d4_logSel      = &d4_log_sel;

	// NEW SELEX
	d3_array _slx_log_par(1,slx_nrow,1,slx_nIpar,1,slx_nJpar);
	for( k = 1; k <= slx_nrow; k++ )
	{
		_slx_log_par(k) = value(slx_log_par(k));
	}
	s_mv.d3_slx_log_par = &_slx_log_par;

	d3_array d3_M(1,n_ags,syr,nyr,sage,nage);
	d3_array d3_F(1,n_ags,syr,nyr,sage,nage);
	for(int ig = 1; ig <= n_ags; ig++ )
	{
		d3_M(ig) = value(M(ig));
		d3_F(ig) = value(F(ig));
	}

	s_mv.d3_M              = &d3_M;
	s_mv.d3_F              = &d3_F;
	s_mv.log_rec_devs      = value(log_rec_devs);
	s_mv.init_log_rec_devs = value(init_log_rec_devs);

	s_mv.q          = value(q);
	s_mv.sbt        = value(sbt);
	s_mv.bt         = value(bt);
	d3_array tmp_ft = value(ft);
	s_mv.d3_ft      = &tmp_ft;

	s_mv.sbo = value(sbo);
	s_mv.so  = value(so);

	s_mv.ft_count = ft_count;
	s_mv.log_ft_pars = value(log_ft_pars);

	dmatrix d_log_q_devs(1,nItNobs,1,qdev_count);
	for(int i = 1; i<=nItNobs; i++)
	{
		d_log_q_devs(i) = value(log_q_devs(i));
	}
	s_mv.log_q_devs  = d_log_q_devs;


	s_mv.log_age_tau2 = value(log_age_tau2);
	s_mv.phi1         = value(phi1);
	s_mv.phi2         = value(phi2);
	s_mv.log_degrees_of_freedom = value(log_degrees_of_freedom);
	




	// |-----------------------------------|
	// | Instantiate Operating Model Class |
	// |-----------------------------------|
	cout<<"Starting Operating Model"<<endl;
	OperatingModel om(s_mv,argc,argv);
	om.runScenario(rseed);
	


	//om.checkMSYcalcs();

	




TOP_OF_MAIN_SECTION
	time(&start);
	arrmblsize = 5000000000;
	gradient_structure::set_GRADSTACK_BUFFER_SIZE(1.e7);
	gradient_structure::set_CMPDIF_BUFFER_SIZE(1.e7);
	gradient_structure::set_MAX_NVAR_OFFSET(5000);
	gradient_structure::set_NUM_DEPENDENT_VARIABLES(5000);
	gradient_structure::set_MAX_DLINKS(40000);


GLOBALS_SECTION
	
	/**
	 * \def NEW_SELEX
	 * Testing new selectivity controls.
	 */
	#define NEW_SELEX

	/**
	\def REPORT(object)
	Prints name and value of \a object on ADMB report %ofstream file.
	*/
	#undef REPORT
	#define REPORT(object) report << #object "\n" << object << endl;
    
	#undef COUT
	#define COUT(object) cout << #object "\n" << object <<endl;

	#undef TINY
	#define TINY 1.e-08

	#undef NA
	#define NA -99.0

	#include <OpenGL/gl.h>
	#include <admodel.h>
	#include <time.h>
	#include <string.h>
	#include "include/lib_iscam.h"
  	#include "milka.h"
  	// #include "mcmc_eval_dic.cpp"


	ivector getIndex(const dvector& a, const dvector& b)
	{
		int i,j,n;
		n = 0;
		j = 1;
		for( i = a.indexmin(); i <= a.indexmax(); i++ )
		{

			 if(b(i) != NA) n++;
		}
		ivector tmp(1,n);
		for( i = a.indexmin(); i <= a.indexmax(); i++ )
		{
			if(b(i) != NA )
			{
				tmp(j++) = a(i);
			}
		}
		
		return(tmp);
	}

	//void readMseInputs()
	//  {
	//  	cout<<"yep this worked"<<endl;
	//  }

	time_t start,finish;
	long hour,minute,second;
	double elapsed_time;
	bool mcmcPhase = 0;
	bool mcmcEvalPhase = 0;
	
	adstring BaseFileName;
	adstring ReportFileName;
	adstring NewFileName;

	adstring stripExtension(adstring fileName)
	{
		/*
		This function strips the file extension
		from the fileName argument and returns
		the file name without the extension.
		*/
		const int length = fileName.size();
		for (int i=length; i>=0; --i)
		{
			if (fileName(i)=='.')
			{
				return fileName(1,i-1);
			}
		}
		return fileName;
	}
	
	

	// age error key
	dmatrix ageErrorKey(const dvector& mu, const dvector& sig, const dvector& x)
	{
	 //RETURN_ARRAYS_INCREMENT();
	 int i, j;
	 double z1;
	 double z2;
	 int si,ni; si=mu.indexmin(); ni=mu.indexmax();
	 int sj,nj; sj=x.indexmin(); nj=x.indexmax();

	 // COUT(si); COUT(sj);
	 // COUT(ni); COUT(nj);
	 dmatrix pdf(si,ni,sj,nj);
	 pdf.initialize();
	 double xs=0.5*(x[sj+1]-x[sj]);
	 for(i=si;i<=ni;i++) //loop true ages
	 {
	    for(j=sj;j<=nj;j++) //loop observed ages
	   {
	     z1=(x(j)-xs-mu(i))/sig(i);
	     z2=(x(j)+xs-mu(i))/sig(i);
	     pdf(i,j)=cumd_norm(z2)-cumd_norm(z1);
	   }//end nbins
	   pdf(i)/=sum(pdf(i));
	 }//end nage
	 
	 //RETURN_ARRAYS_DECREMENT();
	 return(pdf);
	}

	


	
	// #ifdef __GNUDOS__
	//   #include <gccmanip.h>
	// #endif
	// Variables to store results from DIC calculations.
	double dicNoPar = 0;
	double dicValue = 0;


	


// 	void function_minimizer::mcmc_eval(void)
// 	{
// 		// |---------------------------------------------------------------------------|
// 		// | Added DIC calculation.  Martell, Jan 29, 2013                             |
// 		// |---------------------------------------------------------------------------|
// 		// | DIC = pd + dbar
// 		// | pd  = dbar - dtheta  (Effective number of parameters)
// 		// | dbar   = expectation of the likelihood function (average f)
// 		// | dtheta = expectation of the parameter sample (average y) 

// 	  gradient_structure::set_NO_DERIVATIVES();
// 	  initial_params::current_phase=initial_params::max_number_phases;
// 	  uistream * pifs_psave = NULL;

// 	#if defined(USE_LAPLACE)
// 	#endif

// 	#if defined(USE_LAPLACE)
// 	    initial_params::set_active_random_effects();
// 	    int nvar1=initial_params::nvarcalc(); 
// 	#else
// 	  int nvar1=initial_params::nvarcalc(); // get the number of active parameters
// 	#endif
// 	  int nvar;
	  
// 	  pifs_psave= new
// 	    uistream((char*)(ad_comm::adprogram_name + adstring(".psv")));
// 	  if (!pifs_psave || !(*pifs_psave))
// 	  {
// 	    cerr << "Error opening file "
// 	            << (char*)(ad_comm::adprogram_name + adstring(".psv"))
// 	       << endl;
// 	    if (pifs_psave)
// 	    {
// 	      delete pifs_psave;
// 	      pifs_psave=NULL;
// 	      return;
// 	    }
// 	  }
// 	  else
// 	  {     
// 	    (*pifs_psave) >> nvar;
// 	    if (nvar!=nvar1)
// 	    {
// 	      cout << "Incorrect value for nvar in file "
// 	           << "should be " << nvar1 << " but read " << nvar << endl;
// 	      if (pifs_psave)
// 	      {
// 	        delete pifs_psave;
// 	        pifs_psave=NULL;
// 	      }
// 	      return;
// 	    }
// 	  }
	  
// 	  int nsamp = 0;
// 	  double sumll = 0;
// 	  independent_variables y(1,nvar);
// 	  independent_variables sumy(1,nvar);

// 	  do
// 	  {
// 	    if (pifs_psave->eof())
// 	    {
// 	      break;
// 	    }
// 	    else
// 	    {
// 	      (*pifs_psave) >> y;
// 	      sumy = sumy + y;
// 	      if (pifs_psave->eof())
// 	      {
// 	      	double dbar = sumll/nsamp;
// 	      	int ii=1;
// 	      	y = sumy/nsamp;
// 	      	initial_params::restore_all_values(y,ii);
// 	        initial_params::xinit(y);   
// 	        double dtheta = 2.0 * get_monte_carlo_value(nvar,y);
// 	        double pd     = dbar - dtheta;
// 	        double dic    = pd + dbar;
// 	        dicValue      = dic;
// 	        dicNoPar      = pd;

// 	        cout<<"Number of posterior samples    = "<<nsamp    <<endl;
// 	        cout<<"Expectation of log-likelihood  = "<<dbar     <<endl;
// 	        cout<<"Expectation of theta           = "<<dtheta   <<endl;
// 	        cout<<"Number of estimated parameters = "<<nvar1    <<endl;
// 		    cout<<"Effective number of parameters = "<<dicNoPar <<endl;
// 		    cout<<"DIC                            = "<<dicValue <<endl;
// 	        break;
// 	      }
// 	      int ii=1;
// 	      initial_params::restore_all_values(y,ii);
// 	      initial_params::xinit(y);   
// 	      double ll = 2.0 * get_monte_carlo_value(nvar,y);
// 	      sumll    += ll;
// 	      nsamp++;
// 	      // cout<<sumy(1,3)/nsamp<<" "<<get_monte_carlo_value(nvar,y)<<endl;
// 	    }
// 	  }
// 	  while(1);
// 	  if (pifs_psave)
// 	  {
// 	    delete pifs_psave;
// 	    pifs_psave=NULL;
// 	  }
// 	  return;
// 	}
	
	
FINAL_SECTION
	//Make copies of the report file using the ReportFileName
	//to ensure the results are saved to the same directory 
	//that the data file is in. This should probably go in the 
	//FINAL_SECTION
	
	//CHANGED only copy over the mcmc files if in mceval_phase()
	
	#if defined __APPLE__ || defined __linux
	if(last_phase() && !retro_yrs)
	{
		adstring bscmd = "cp iscam.rep " +ReportFileName;
		system(bscmd);
		
		bscmd = "cp iscam.par " + BaseFileName + ".par";
		system(bscmd); 
		
		bscmd = "cp iscam.std " + BaseFileName + ".std";
		system(bscmd);
		
		bscmd = "cp iscam.cor " + BaseFileName + ".cor";
		system(bscmd);
		
		//if( SimFlag )
		//{
		//	bscmd = "cp iscam.sim " + BaseFileName + ".sim";
		//	system(bscmd);
		//}

		if( mcmcPhase )
		{
			bscmd = "cp iscam.psv " + BaseFileName + ".psv";
			system(bscmd);
			
			cout<<"Copied binary posterior sample values"<<endl;
		}
		
		if( mcmcEvalPhase )
		{		
			bscmd = "cp iscam.mcmc " + BaseFileName + ".mcmc";
			system(bscmd);
		
			bscmd = "cp sbt.mcmc " + BaseFileName + ".mcst";
			system(bscmd);
		
			bscmd = "cp rt.mcmc " + BaseFileName + ".mcrt";
			system(bscmd);
			
			ofstream mcofs(ReportFileName,ios::app);
			mcofs<<"ENpar\n"<<dicNoPar<<endl;
			mcofs<<"DIC\n"<<dicValue<<endl;
			mcofs.close();
			cout<<"Copied MCMC Files"<<endl;
		}
	}

	if( last_phase() && retro_yrs )
	{
		//copy report file with .ret# extension for retrospective analysis
		adstring bscmd = "cp iscam.rep " + BaseFileName + ".ret" + str(retro_yrs);
		system(bscmd);
	}
	#endif

	#if defined _WIN32 || defined _WIN64
	if(last_phase() && !retro_yrs)
	{
		adstring bscmd = "copy iscam.rep " +ReportFileName;
		system(bscmd);
		
		bscmd = "copy iscam.par " + BaseFileName + ".par";
		system(bscmd); 
		
		bscmd = "copy iscam.std " + BaseFileName + ".std";
		system(bscmd);
		
		bscmd = "copy iscam.cor " + BaseFileName + ".cor";
		system(bscmd);
		
		if( mcmcPhase )
		{
			bscmd = "copy iscam.psv " + BaseFileName + ".psv";
			system(bscmd);
			
			cout<<"Copied binary posterior sample values"<<endl;
		}
		
		if( mcmcEvalPhase )
		{		
			bscmd = "copy iscam.mcmc " + BaseFileName + ".mcmc";
			system(bscmd);
		
			bscmd = "copy sbt.mcmc " + BaseFileName + ".mcst";
			system(bscmd);
		
			bscmd = "copy rt.mcmc " + BaseFileName + ".mcrt";
			system(bscmd);
		
			cout<<"Copied MCMC Files"<<endl;
		}
	}

	if( last_phase() && retro_yrs )
	{
		//copy report file with .ret# extension for retrospective analysis
		adstring bscmd = "copy iscam.rep " + BaseFileName + ".ret" + str(retro_yrs);
		system(bscmd);
	}
	#endif


	if(mseFlag) runMSE();
	cout<<"End of class testing"<<endl;

	//  Print run time statistics to the screen.
	time(&finish);
	elapsed_time=difftime(finish,start);
	hour=long(elapsed_time)/3600;
	minute=long(elapsed_time)%3600/60;
	second=(long(elapsed_time)%3600)%60;
	cout<<endl<<endl<<"*******************************************"<<endl;
	cout<<"--Start time: "<<ctime(&start)<<endl;
	cout<<"--Finish time: "<<ctime(&finish)<<endl;
	cout<<"--Runtime: ";
	cout<<hour<<" hours, "<<minute<<" minutes, "<<second<<" seconds"<<endl;
	cout<<"--Number of function evaluations: "<<nf<<endl;
	cout<<"--Results are saved with the base name:\n"<<"\t"<<BaseFileName<<endl;
	cout<<"*******************************************"<<endl;

