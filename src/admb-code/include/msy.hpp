#ifndef _MSY_H
#define _MSY_H

#ifdef MAXITER
#undef MAXITER
#define MAXITER 100
#endif

#ifdef TOL
#undef TOL
#define TOL     1.e-08
#endif

#include <admodel.h>
#include <fvar.hpp>


namespace rfp {




	/**
	 * @brief Base class for reference point calculations
	 * @details The base class for MSY and SPR-based reference point 
	 * calculations.
	 * 
	 * @param fe vector of fishing mortality rates
	 * @return getFmsy is a pure virtual function.
	 */
	template<typename T, typename T1, typename T2>
	class referencePoints 
	{
	private:
		
		T1 m_fe;

	public:
		
		// Pure virtual functions... set = 0;
		virtual const T1 getFmsy(const T1 &fe) const = 0;
		// virtual const Type getBmsy(const Type &be) const = 0;

		virtual ~referencePoints(){}

		void setFe(T1 & fe) { this -> m_fe = fe; }
		T1 getFe()    const { return m_fe;     }
		
	};



	/**
	 * @brief MSY-based reference points
	 * @details Class object for computing MSY-based reference points.
	 * 
	 * @author Steven Martell
	 * 
	 * @tparam T variable
	 * @tparam T1 vector
	 * @tparam T2 matrix
	 * @tparam T3 3d_array
	 */
	template<class T, class T1, class T2, class T3>
	class msy //: public referencePoints<T,T1,T2>
	{  
	private:
		// Indexes for dimensions
		int m_sage;
		int m_nage;
		int m_nGear;
		int m_nGrp;
		

		T m_ro;			/// Unfished equilibrium recruits
		T m_bo;			/// Unfished equilibrium biomass
		T m_rmsy;		/// Recruitment at MSY
		T m_be;			/// Equilibrium biomass
		T m_re;			/// Equilibrium recruitment
		T m_h;			/// Steepness
		T m_rho;	    /// Fraction of mortality that occurs before spawning.
		T m_phie;		/// Spawning biomass per recruit in unfished conditions.
		T m_phif;		/// Spawning biomass per recruit in fished conditions.
		T m_spr;        /// Spawning potential ratio.
		T m_bmsy;		/// Spawning biomass at MSY
		T m_dYe;		/// Derivative of total yield.
		T m_d2Ye;		/// Second derivative of total yield.
		T m_fbar_stp;	/// Newton step for average F.

		T1 m_fe;		/// Fishing mortality rate
		T1 m_fmsy;      /// Fishing mortality rate at MSY
		T1 m_fstp;		/// Newton step size
		T1 m_ye;		/// Equilibrium yield for each gear.
		T1 m_phiq;		/// Per recruit Yield.
		T1 m_dye;		/// Derivative of catch equation for each gear.
		T1 m_dre;		/// Partial derivative of recruitment with respect to fe
		T1 m_dphiq;     /// Partial derivative for per recruit yield.
		T1 m_msy;		/// Maximum Sustainable yield for each gear.
		T1 m_allocation;/// Allocation of ye to each gear.
		T1 m_ak;        /// Input allocation.

		T2 m_lz;		/// Survivorship under fished conditions
		T2 m_lx; 		/// Survivorship upder unfished conditions


		T2 m_Ma;		/// Natural mortality rate matrix.
		T2 m_Wa;		/// Weight-at-age matrix.
		T2 m_Fa;		/// Fecundity-at-age matrix.

		T3 m_Va;		/// Selectivity-at-age.
		//T3 m_dlz; 		/// first derivative of lz
		//T3 m_ddlz; 		/// second derivative of lz


		void calcPhie();
		void calcEquilibrium(const T1 &fe);
		
		//void calcEquilibrium(const T1 &fe);

	public:
		// default constructor
		msy(const T  ro ,
		    const T  h  ,
		    const T  rho,
		    const T2 ma ,
		    const T2 wa ,
		    const T2 fa ,
		    const T3 V )
		:m_ro(ro),m_h(h),m_rho(rho),m_Ma(ma),m_Wa(wa),m_Fa(fa),m_Va(V) 
		{
			//m_Va.allocate(*V);
			//m_Va = *V;

			if(m_Ma.indexmin() != m_Fa.indexmin() || m_Ma.indexmax() != m_Fa.indexmax())
			{
			cerr<<"Indexes do not mach in calcPhie"<<endl;
			exit(1);
			}

			m_nGrp = m_Ma.rowmax() - m_Ma.rowmin() + 1;
			m_nGear = m_Va(1).rowmax();
			//cout<<"NGEAR "<<m_nGear<<endl;
			
			m_sage = m_Ma.colmin();
			m_nage = m_Ma.colmax();

			calcPhie();

			//cout<<"In constructor\n"<<m_phie<<endl;
		}
		virtual const T1 getFmsy(const T1 &fe);
		virtual const T1 getFmsy(const T1 &fe, const T1 &ak);

		// Getters
		virtual const T  getBo()   {return m_bo;  }
		virtual const T  getRt()   {return m_re;  }
		virtual const T  getRmsy() {return m_rmsy;}
		virtual const T  getBmsy() {return m_bmsy;}
		virtual const T1 getMsy()  {return m_msy; }
		virtual const T1 getAllocation() {return m_allocation; }
		//virtual const T1 getdYe()  {return m_dYe; }
		
		void print();
		void checkDerivatives(const T1 & fe);
		
	};

	template<class T,class T1,class T2,class T3>
	void msy<T,T1,T2,T3>::print()
	{
		cout<<"|------------------------------------------|" <<endl;
		cout<<"| MSY-BASED REFERENCE POINTS               |" <<endl;
		cout<<"|------------------------------------------|" <<endl;
		cout<<"| Bo         = "<<setw(10)<<m_bo              <<endl;
		cout<<"| Re         = "<<setw(10)<<m_re              <<endl;
		cout<<"| Rmsy       = "<<setw(10)<<m_rmsy            <<endl;
		cout<<"| Bmsy       = "<<setw(10)<<m_bmsy            <<endl;
		cout<<"| Fmsy       = "<<setw(10)<<m_fmsy            <<endl;
		cout<<"| MSY        = "<<setw(10)<<m_msy             <<endl;
		cout<<"| ∑MSY       = "<<setw(10)<<sum(m_msy)        <<endl;
		cout<<"| Allocation = "<<setw(10)<<m_allocation      <<endl;
		cout<<"| SPR        = "<<setw(10)<<m_spr             <<endl;
		cout<<"|------------------------------------------|" <<endl;
		cout<<"| DIAGNOSTICS                              |" <<endl;
		cout<<"|------------------------------------------|" <<endl;
		cout<<"| dye/dfe    = "<<setw(10)<<m_dye             <<endl;
		cout<<"| ∑dye/dfe   = "<<setw(10)<<m_dYe             <<endl;
		// cout<<"| BPR  = "<<setw(10)<<m_phie                  <<endl;
		// cout<<"| bpr  = "<<setw(10)<<m_phif                  <<endl;
		// cout<<"| dYes = "<<setw(10)<<sum(m_f)                <<endl;
		// cout<<"| FAIL = "<<setw(10)<<m_FAIL                  <<endl;
		cout<<"|------------------------------------------|" <<endl;
	}

	/**
	 * @brief Check the derivative calculations.
	 * @details Numerically check the analytical partial derivative calculations.
	 * 
	 * @param fe vector of fishing mortality rates.
	 * @tparam T double
	 * @tparam T2 matrix
	 * @return Prints Table of analytical & numerical derivatives.
	 */
	template<class T, class T1, class T2,class T3>
	void msy<T,T1,T2,T3>::checkDerivatives(const T1& fe)
	{
		double hh = 1.0e-5;
		double r1,r2;
		dvector y1(1,m_nGear);
		dvector y2(1,m_nGear);
		dvector fh(1,m_nGear);
		dvector q1(1,m_nGear);
		dvector q2(1,m_nGear);
		//dmatrix lz1(1,m_nGrp,m_sage,m_nage);
		//d3_array lz2(1,m_nGear,1,m_nGrp,m_sage,m_nage); 

		calcEquilibrium(fe);
		y1 = m_ye;
		r1 = m_re;
		q1 = m_phiq;
		//lz1 = m_lz;
		
		for(int k = 1; k <= m_nGear; k++ )
		{
			fh = fe;
			fh(k) += hh;
			calcEquilibrium(fh);
			y2 = (m_ye - y1)/hh;
			r2 = (m_re - r1)/hh;
			q2 = (m_phiq - q1)/hh;
			

			cout<<"|———————————————————————————————————————————————————————|" <<endl;
			cout<<"| Gear "<<k<<" fe\t"<<fe(k)<<endl;
			cout<<"| Variable"<<setw(15)<<std::setfill(' ')
				<<"Numerical" <<setw(15)<<std::setfill(' ')
				<<"Analytical"<<setw(15)<<std::setfill(' ')
				<<"Difference"<<endl;
			cout<<"|———————————————————————————————————————————————————————|" <<endl;
			cout<<"| dye/dfe "         <<setw(15)
					<<y2(k)            <<setw(15)
					<<m_dye(k)         <<setw(15)
					<<y2(k)-m_dye(k)   <<endl;
			cout<<"| dre/dfe "         <<setw(15)
					<<r2               <<setw(15)
					<<m_dre(k)         <<setw(15)
					<<r2-m_dre         <<endl;
			cout<<"| dphiq/dfe"        <<setw(15)
					<<q2(k)            <<setw(15)
					<<m_dphiq(k)       <<setw(15)
					<<q2(k)-m_dphiq(k) <<endl;
		}
		cout<<"|———————————————————————————————————————————————————————|" <<endl;
		//exit(1);
	}

	/**
	 * @brief Calculate Fmsy given fixed allocation.
	 * @details Calculate Fmsy for a given allocation vector ak.
	 * This function returns a vector fishing mortality rates that
	 * will maximize the sum of yields over all fleets.
	 * 
	 * @param fe Fishing mortality rate
	 * @param ak Allocation to each fleet
	 * @tparam T double
	 * @tparam T2 Matrix
	 * @tparam T3 3darray
	 * @return Returns a vector of fishing mortality rates.
	 */
	template<class T, class T1, class T2, class T3>
	const T1 msy<T,T1,T2,T3>::getFmsy(const T1 &fe, const T1 &ak)
	{
		T lb = 1.0e-10;				//set lower bound for fbar
		T ub = 5.0e+01;				//set upper bound for fbar
		
		T fbar  = mean(fe);  		// average mortality rate
		T1 fk = fe; 				// set fk to the Fstarting values
		T1 pk = ak / sum(ak);	  	// proportion of total catch
		T1 lambda = pk / mean(pk); 	// allocation of f - multiplies fbar
		m_fe = fe; 					// set m_fe to initial fe guesses
		m_ak = ak; 					// set allocation to pre-defined values

		for(int iter = 1; iter <= MAXITER; iter++ )
		{
			fk = fbar; 								// set all f to fbar
			calcEquilibrium(fk); 					// see function calcEquilibrium
			lambda = elem_div(pk,m_ye/sum(m_ye)); 	// Question: why divide pk by the yield proportions?

			fk = fbar * lambda/mean(lambda); 		// vector of allocated f
			calcEquilibrium(fk);

			// fbar = fbar - m_dYe/m_d2Ye;
			fbar -= m_fbar_stp;
			// cout<<iter<<" fbar "<<fbar<<" dYe "<<m_dYe<<" fk "<<fk;
			// cout<<" lambda = "<<lambda<<" ak = "<<m_ye/sum(m_ye)<<endl;

			// Backtrack if necessary;
			if( (lb-fbar)*(fbar-ub) < 0.0 )
			{
				// fbar += 0.98 * m_dYe/m_d2Ye;
				fbar += 0.98 * m_fbar_stp;
			}
			
			// cout<<iter<<" Fe = "<<m_fbar_stp<<endl;
			if( fabs(m_fbar_stp) < TOL ) break;
		}
		m_fe = fk;
		m_rmsy = m_re; 
		m_fmsy = m_fe;
		m_bmsy = m_be;
		m_msy  = m_ye;
		m_allocation = m_msy/sum(m_msy);
		return m_fe;
	}

	/**
	 * @brief get Fmsy vector
	 * @details Use Newton Raphson method to determine Fmsy while maximizing the sum
	 * of yields for all fleets.  Uses a backtrack method if estimates of Fmsy are 
	 * outsize the lower and upper bounds.
	 * 
	 * @param fe vector of fishing mortality rates
	 * @tparam T Number
	 * @tparam T2 Matrix
	 * @tparam T3 d3_array
	 * @return Returns Fmsy.
	 */
	template<class T, class T1, class T2, class T3>
	const T1 msy<T,T1,T2,T3>::getFmsy(const T1 & fe)
	{
		int n = size_count(fe);
		T lb = 1.0e-10;
		T ub = 5.0e+01;
		T delta = 1.0;
		T1 ftry = fe;
		m_ak.deallocate();
		m_fe = fe;
		for(int iter=1; iter<=MAXITER; iter++)
		{
			calcEquilibrium(m_fe);
			m_fe = m_fe +  m_fstp;
			
			// Backtrack if outside boundary conditions
			for(int i = 1; i <= n; i++ )
			{
				T bt = (lb-m_fe(i))*(m_fe(i)-ub);
				if( bt < 0.0 )
				{
					delta    = 0.99;
					m_fe(i) -= delta*m_fstp(i);
				}
			}
			//cout<<iter<<" delta = "<<delta<<" fmsy = "<<m_fe<<endl;
			
			
		}
		m_msy = m_ye;
		m_allocation = m_msy/sum(m_msy);
		m_bmsy = m_be;
		m_fmsy = m_fe;
		return(m_fe);	
	}

	template<class T, class T1, class T2, class T3>
	void msy<T,T1,T2,T3>::calcEquilibrium(const T1 &fe)
	{
		
		int j,h,k,kk;
		T phif = 0.0;
		

		T1 pza(m_sage,m_nage);				// pre-spawning total mortality
		T1 psa(m_sage,m_nage); 				// pre-spawning survivorship
		T1 poa(m_sage,m_nage); 				// Question: What is poa, where is it used?		

		T2  za(1,m_nGrp,m_sage,m_nage); 	// Total mortality at age by group
		T2  sa(1,m_nGrp,m_sage,m_nage); 	// Survivorship at age by group
		T2  oa(1,m_nGrp,m_sage,m_nage); 	// 1-sa
		T2  lz(1,m_nGrp,m_sage,m_nage); 	// Survivorship under fished conditions
		T2  lw(1,m_nGrp,m_sage,m_nage); 	// pre-spawning survivorship unde fished conditions

		T2   qa(1,m_nGear,m_sage,m_nage); 	// per recruit yield (baranov without f and N)
		T2  dlz(1,m_nGear,m_sage,m_nage); 	// derivative of lz with respect to f
		
		T2 d2lz(1,m_nGear,m_sage,m_nage); 	// second derivative of lz with respect to f
		T2  dlw(1,m_nGear,m_sage,m_nage);
		T2 d2lw(1,m_nGear,m_sage,m_nage);
		dlz.initialize();
		dlw.initialize();
		d2lz.initialize();
		d2lw.initialize();

		T3   qa_m(1,m_nGrp,1,m_nGear,m_sage,m_nage); 	// gear specific per recruit yield 
		T3  dlz_m(1,m_nGrp,1,m_nGear,m_sage,m_nage);  	// gear specific derivative of survivorship under fished conditions 
		T3 d2lz_m(1,m_nGrp,1,m_nGear,m_sage,m_nage); 	// gear specific second derivative of survivorship under fished conditions
		T3  dlw_m(1,m_nGrp,1,m_nGear,m_sage,m_nage); 	// gear specific derivative of pre-spawning survivorship under fished conditions
		T3 d2lw_m(1,m_nGrp,1,m_nGear,m_sage,m_nage); 	// gear specific second derivative of pre-spawning survivorship under fished conditions

		//cout<<m_Va<<endl;
		for( h = 1; h <= m_nGrp; h++ )
		{
			za(h) = m_Ma(h); 							//set Z to natural mortality
			for( k = 1; k <= m_nGear; k++ )
			{
				za(h) = za(h) + fe(k) * m_Va(h)(k); 	// add fishing mortality
				//cout<<h<<" "<<k<<endl;
			}
			sa(h) = exp(-za(h));  					// survival
			oa(h) = 1.0 - sa(h); 					
			pza   = m_rho*za(h); 					// pre-spawning total mortality
			psa   = exp(-pza); 						// pre-spawning survival
			poa   = 1.0 - elem_prod(sa(h),psa);
			
			for(k=1;k<=m_nGear;k++)
			{
				qa(k)      = elem_div(elem_prod(elem_prod(m_Va(h)(k),m_Wa(h)),oa(h)),za(h)); // per recruit 
				qa_m(h)(k) = qa(k); 														

				// the dlw derivatives were not throughly checked. 
				dlw(k,m_sage)      = -psa(m_sage)*m_rho*m_Va(h)(k)(m_sage); 				//  derivative of pre-spawning survivorship at sage
				dlw_m(h,k,m_sage)  = dlw(k,m_sage);
				d2lw(k,m_sage)     = psa(m_sage)*square(m_rho)*square(m_Va(h)(k)(m_sage)); 	// second derivative of pre-spawning survivorship at sage
				d2lw_m(h,k,m_sage) = d2lw(k,m_sage);

				dlz(k,m_sage)      = 0; 	// set all derivatives and second derivatis lz(sage) to 0
				dlz_m(h,k,m_sage)  = 0;
				d2lz(k,m_sage)     = 0;
				d2lz_m(h,k,m_sage) = 0;
			}

			// Survivorship
			lz(h)(m_sage) = 1.0/m_nGrp; 				// Question: Why 1/ngroup? Doesn't it mean that all groups contribute equally to the population?	
			lw(h)(m_sage) = 1.0/m_nGrp * psa(m_sage); 	
			for( j = m_sage+1; j <= m_nage; j++ )
			{
				lz(h,j) = lz(h,j-1) * sa(h,j-1);
				lw(h,j) = lz(h,j) * psa(j); 

				if( j == m_nage )
				{
					//plus age
					lz(h,j) = (lz(h,j-1)* sa(h,j-1))/oa(h,j);
					lw(h,j) = lz(h,j)*psa(j); 
				}

				for( k = 1; k <= m_nGear; k++ )
				{
					// derivatives for survivorship 
					dlz(k)(j)  = sa(h)(j-1)*(dlz(k)(j-1) - lz(h)(j-1)*m_Va(h)(k)(j-1)); 					
					
					d2lz(k)(j) = sa(h)(j-1)*(d2lz(k)(j-1)+lz(h)(j-1)*square(m_Va(h)(k)(j-1))+2*dlz(k)(j-1)*m_Va(h)(k)(j-1));
					
					// derivatives for spawning survivorship
					
					dlw(k)(j)  = -lz(h)(j)*m_rho*m_Va(h)(k)(j)*psa(j); 
					d2lw(k)(j) =  lz(h)(j)*square(m_rho)*square(m_Va(h)(k)(j))*psa(j);

					if( j == m_nage ) // + group derivatives
					{
						dlz(k)(j)  = (1/oa(h,j))*(sa(h)(j-1)*(dlz(k)(j-1)-lz(h)(j-1)*m_Va(h)(k)(j-1))-(lz(h)(j-1)*sa(h)(j-1)*m_Va(h)(k)(j)*sa(h)(j))/oa(h,j));
						
						dlw(k)(j)  = -lz(h)(j-1)*sa(h)(j-1)*m_rho*m_Va(h)(k)(j)/oa(h)(j)
									- lz(h)(j-1)*psa(j)*m_Va(h)(k)(j)*sa(h)(j)
									/square(oa(h)(j));
						
						T V1  	   = m_Va(h)(k)(j-1);
						T V2  	   = m_Va(h)(k)(j);
						T oa2 	   = oa(h)(j)*oa(h)(j);
						
						d2lz(k)(j) = (1/oa(h,j))*sa(h)(j-1)*(d2lz(k)(j-1)+lz(h)(j-1)*square(V1)+2*dlz(k)(j-1)*V1)
							+ (lz(h)(j-1)*sa(h)(j-1)*square(V2)*sa(h)(j))/oa2
							+ (2*lz(h)(j-1)*sa(h)(j-1)*square(V2)*square(sa(h)(j)))/(oa2*oa(h,j))
							- (2*sa(h)(j-1)*(dlz(k)(j-1)-lz(h)(j-1)*V1)*V2*sa(h)(j))/(oa2);


						d2lw(k)(j) = lz(h)(j-1)*square(m_rho)*square(V2)*psa(j)/oa(h)(j)
									+ 2*lz(h)(j-1)*m_rho*square(V2)*psa(j)*sa(h)(j)/oa2
									+ 2*lz(h)(j-1)*psa(j)*square(V2)*square(sa(h)(j))
									/(oa(h)(j)*oa2)
									+ lz(h)(j-1)*psa(j)*square(V2)*sa(h)(j)/oa2;
					}
					dlz_m(h,k,j)  =  dlz(k)(j);
					//m_dlz(h,k,j)  = dlz_m(h,k,j);
					d2lz_m(h,k,j) = d2lz(k)(j);
					dlw_m(h,k,j)  =  dlw(k)(j);
					d2lw_m(h,k,j) = d2lw(k)(j);
				} // m_nGear
			} // m_nage
			//exit(1);

			// Spawning biomass per recruit in fished conditions.
			phif += lz(h) * m_Fa(h);
			// phif += lw(h) * m_Fa(h);

		} // m_nGrp
		m_phif  = phif;
		m_lz    = lz;

		// Incidence functions and associated derivatives
		T1   dphif(1,m_nGear);   dphif.initialize();
		T1  d2phif(1,m_nGear);  d2phif.initialize();
		T1    phiq(1,m_nGear);    phiq.initialize();
		
		
		T1     dre(1,m_nGear);     dre.initialize();
		T1    d2re(1,m_nGear);    d2re.initialize();
		// T1      t1(m_sage,m_nage);  t1.initialize();
		T1      tj(m_sage,m_nage);  tj.initialize();

		T2   dphiq(1,m_nGear,1,m_nGear);   dphiq.initialize();  
		T2  d2phiq(1,m_nGear,1,m_nGear);  d2phiq.initialize();

		

		for( h = 1; h <= m_nGrp; h++ )
		{
			T3   dqa(1,m_nGear,1,m_nGear,m_nage,m_sage);   dqa.initialize();  
			T3  d2qa(1,m_nGear,1,m_nGear,m_nage,m_sage);  d2qa.initialize();
			
			for( k = 1; k <= m_nGear; k++ )
			{
				dphif(k)  += dlz_m(h)(k)  * m_Fa(h); 		// derivative of biomass per recruit
				d2phif(k) += d2lz_m(h)(k) * m_Fa(h); 		// second derivative of biomass per recruit
				// dphif(k)   += dlw_m(h)(k)  * m_Fa(h);
				// d2phif(k)  += d2lw_m(h)(k) * m_Fa(h);

				// per recruit yield
				phiq(k)   +=  lz(h) * qa_m(h)(k);

				for( kk = 1; kk <= m_nGear; kk++ )
				{	
					/*				
					// changed back to ngear==1 to be consistent with spreadsheet.
					if(m_nGear==1)  // was (if ngear==1), changed during debugging of nfleet>1
					{
						// dphiq = wa*oa*va*dlz/za + lz*wa*va^2*sa/za - lz*wa*va^2*oa/za^2
						t1 = elem_div(elem_prod(elem_prod(lz(h),m_Wa(h)),square(m_Va(h)(k))),za(h));
					}
					else
					{
						// dphiq = wa*oa*va*dlz/za + lz*wa*va*sa/za - lz*wa*va*oa/za^2
						t1 = elem_div(elem_prod(elem_prod(lz(h),m_Wa(h)),m_Va(h)(k)),za(h));

						// djphiq = wa*oa*va(i)/dlz/za + lz*wa*va(i)*va(j)*sa/za - lz*wa*va(i)*va(j)*oa/za^2
					}*/
					// dphiq = wa*oa*va*dlz/za + lz*wa*va*sa/za - lz*wa*va*oa/za^2
					
					T1 va2 = elem_prod(m_Va(h)(k),m_Va(h)(kk));
					T1 t0  = elem_div(oa(h),za(h));
					T1 t1  = elem_div(elem_prod(va2,m_Wa(h)),za(h));
					T1 t3  = sa(h)-t0;
					 

					dqa(k)(kk) = elem_prod(t1,t3);

					dphiq(k)(kk)  += qa_m(h)(k)* dlz_m(h)(kk) + dqa(k)(kk) * m_lz(h);


					// 2nd derivative for per recruit yield (nasty)
					
					T1 p1  = elem_prod(elem_prod(m_Va(h)(k),m_Va(h)(kk)),m_Va(h)(kk));
					T1 p2  = elem_div(elem_prod(p1,m_Wa(h)),za(h));
					T1 p3  = 2. *elem_div(sa(h),za(h));
					T1 p4  = 2. *elem_div(oa(h),elem_prod(za(h),za(h)));
					T1 p5  = -sa(h)-p3+p4;



					d2qa(k)(kk) =  elem_prod(p2,p5);

					d2phiq(k)(kk)  += d2lz_m(h)(kk)*qa_m(h)(k) 
								+ 2.* dlz_m(h)(kk)*dqa(k)(kk) + d2qa(k)(kk) * m_lz(h) ;


					//T1 t2  = 2. * dlz_m(h)(kk);
					//T1 V2  = elem_prod(m_Va(h)(k),m_Va(h)(kk));
					//T1 t5  = elem_div(elem_prod(m_Wa(h),V2),za(h));
					//T1 t7  = elem_div(m_Va(h)(kk),za(h));
					//T1 t9  = elem_prod(t5,sa(h));
					//T1 t11 = elem_prod(t5,t0);
					//T1 t13 = elem_prod(lz(h),t5);
					//T1 t14 = elem_prod(m_Va(h)(kk),sa(h));
					//T1 t15 = elem_prod(t7,sa(h));
					//T1 t17 = elem_prod(m_Va(h)(kk),t0);
					//T1 t18 = elem_div(t17,za(h));
					
					//d2phiq(k)(kk)  += d2lz_m(h)(kk)*qa_m(h)(k) 
					//			+ t2*t9 - t2*t11 - t13*t14 -2.*t13*t15 
					//			+ 2.*t13*t18;

				} // m_nGear kk loop
			} // m_nGear k loop
		} // m_nGrp
		m_phiq  = phiq;
		m_dphiq = diagonal(dphiq);
		

		// 1st & 2nd partial derivatives for recruitment
		T phif2 = square(m_phif);
		T kappa = 4.0*m_h/(1.-m_h);
		T km1   = kappa - 1.0;
		for( k = 1; k <= m_nGear; k++ )
		{
			dre(k)      = m_ro*m_phie*dphif(k)/(phif2*km1);
			d2re(k)     = -2.*m_ro*m_phie*dphif(k)*dphif(k)/(phif2*phif*km1) 
						+ m_ro*m_phie*d2phif(k)/(phif2*km1);		
		}	
		m_dre = dre;

		// Equilibrium calculations
		T    re;
		T    be;
		T1    ye(1,m_nGear);
		T1  fstp(1,m_nGear);
		T1   dye(1,m_nGear);
		T2 d2ye(1,m_nGear,1,m_nGear);
		T2 invJ(1,m_nGear,1,m_nGear);

		// Equilibrium recruits, yield and first derivative of ye
		re   = m_ro*(kappa-m_phie/phif) / km1;
		re<0?re=0.01:re=re;  // could try setting re =0 instead of 0.01
		ye   = re*elem_prod(fe,phiq);
		be   = re * phif;
		dye  = re*phiq 
			  + elem_prod(elem_prod(fe,phiq),dre) 
			  + re*elem_prod(fe,diagonal(dphiq));  
			  

		// cout<<"dye "<<dye<<endl;

		// Jacobian matrix (2nd derivative of the catch equations)
		// This could be suspect, SM to check, CW to prove me wrong
		for(k=1; k<=m_nGear; k++)
		{
			for(kk=1; kk<=m_nGear; kk++)
			{
				d2ye(k)(kk) = fe(k)*phiq(k)*d2re(kk) 
				             + 2.*fe(k)*dre(kk)*dphiq(k)(kk) 
				             + fe(k)*re*d2phiq(k)(kk);
				if(k == j)
				{
					d2ye(k)(kk) += 2.*dre(kk)*phiq(k)+2.*re*dphiq(k)(kk);
				}
			} 
		}

		// Inverse of the Jacobi
		invJ = -inv(d2ye);
		fstp = dye * invJ;
		// Set private member variables
		m_fstp = fstp;
		m_ye   = ye;
		m_be   = be;
		m_re   = re;
		m_rmsy = m_re;
		m_dye  = dye;
		m_dYe  = sum(dye);
		m_d2Ye = sum(diagonal(d2ye));
		m_spr  = m_phif/m_phie;

		// Derivative based on fixed allocations
		// dye_ak = ak*dre*∑(fk*phik) + ak*re*(∑phik + Fi*dphi[i]/dFi + Fj*dphi[j]/dFi)
		T1 dye_ak(1,m_nGear);
		T2 d2ye_ak(1,m_nGear,1,m_nGear);
		if(allocated(m_ak)) 
		{	
			//cout<<"Allocated"<<endl;
			for( k = 1; k <= m_nGear; k++ )
			{

				dye_ak(k) = m_ak(k)*dre(k)*(fe*phiq)
				          + m_ak(k)*re * (sum(phiq) + fe*dphiq(k));

				          // The above may also be fe*column(dphiq,k)?? 
				// Now the second derivative
				for( kk = 1; kk <= m_nGear; kk++ )
				{
					d2ye_ak(k)(kk) = m_ak(k)*d2re(kk)*(fe*phiq)
					               + 2.0*m_ak(k)*dre(kk)*( sum(phiq)+fe*dphiq(kk) ) 
					               + m_ak(k)*re*( 2.0*sum(diagonal(dphiq))+fe*d2phiq(kk) ); //Question: why use sum of dphiq? Also in the spreadsheet m_ak is not used for the second derivatives
				}

			}	
			m_fbar_stp = sum(dye_ak)/sum(diagonal(d2ye_ak));
			m_dye      = dye_ak;
			m_dYe      = sum(dye_ak);
			m_d2Ye     = sum(diagonal(d2ye_ak));
			// cout<<sum(dye_ak)/sum(diagonal(d2ye_ak))<<endl;
		}

		 //Uncomment for debugging.
		 cout<<setprecision(8)<<endl;
		 cout<<"Re     = "<<re<<endl;
		 cout<<"phie   = "<<m_phie<<endl;
		 cout<<"phif   = "<<m_phif<<endl;
		 cout<<"fe     = "<<fe<<endl;
		 cout<<"dphif  = "<<dphif<<endl;
		 cout<<"ddphif = "<<d2phif<<endl;  	// minor diff  FIXED
		 cout<<"ye     = "<<ye<<endl;
		 cout<<"phiq   = "<<phiq<<endl;
		 cout<<"dphiq  = "<<dphiq<<endl;   	// Bug: FIXED for ngear > 1
		 cout<<"d2phiq = "<<d2phiq<<endl;  	// OK
		 cout<<"dre    = "<<dre<<endl;		// OK
		 cout<<"dye    = "<<dye<<endl;     	// Bug -> FIXED.
		 cout<<"Jacobi\n "<<d2ye<<endl;
		 cout<<"invJ \n  "<<invJ<<endl;
		 cout<<"fstp   = "<<fstp<<endl;		// Bug -> FIXED.
		cout<<"d2lz_m = "<<d2lz_m<<endl;  // plus group is different.
		cout<<"Newton step\n"<<fstp<<endl;
		cout<<"End of CalcSurvivorship"<<endl;
	}

	/**
	 * @brief Calculate spawning biomass per recruit.
	 * @details Calculate spawning biomass per recruit based on survivorship and maturity
	 * at age.
	 * 
	 * @author Steven Martell
	 * 
	 * @param rho Fraction of natural mortality that occurs prior to spawning.
	 * @param Ma Natural mortality rate at age and sex
	 * @param Fa Maturity-at-age and sex
	 * @tparam T1 Vector
	 * @tparam T2 Matrix
	 */
	template<class T, class T1, class T2, class T3>
	void msy<T,T1,T2,T3>::calcPhie()
	{
		int i,j;
		
		m_phie = 0;
		T2 lx(1,m_nGrp,m_sage,m_nage);
		lx.initialize();
		for( i = 1; i <= m_nGrp; i++ )
		{
			 for( j = m_sage; j <= m_nage; j++ )
			 {
			 	lx(i,j) = exp(-m_Ma(i,j)*(j-m_sage));// - m_rho*m_Ma(i,j));
			 	if(j==m_nage) lx(i,j) /= 1.0 -exp(-m_Ma(i,j));
			 }
			 m_phie += 1./(m_nGrp) * lx(i) * m_Fa(i);
		}
		m_lx = lx;
		m_bo = m_ro * m_phie;
		// cout<< "lx\n"<<lx<<endl;
		// cout<<"Bo = "<<m_bo<<endl;
		
	}




	// template<class Type>
	// class spr : public referencePoints<Type>
	// {
	// public:
	// 	spr();
	// 	~spr();
	// };
} //rfp


#endif