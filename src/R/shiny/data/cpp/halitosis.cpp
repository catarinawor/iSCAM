#include <Rcpp.h>


using namespace Rcpp;


// [[Rcpp::plugins(cpp11)]]

// [[Rcpp::export]]
NumericVector gvonb_cpp (NumericVector t, double linf, double vbk, double to, double p)
{
	NumericVector l = linf * pow((1.0 - exp(-vbk*(t - to))),p);
				  
	return(l);
}

// [[Rcpp::export]]
NumericVector plogis95_cpp (NumericVector x,double s50, double s95)
{
	return ( 1.0/(1.0+exp(-log(19)*(x-s50)/(s95-s50))) );
}





class Uniform { public:
    Uniform(double min_, double max_) : min(min_), max(max_) {}
    NumericVector draw(int n) const {
        RNGScope scope;
		return runif( n, min, max ); }
    double min, max;
};
double uniformRange( Uniform* w) { return w->max - w->min;
}
RCPP_MODULE(unif_module) {
    class_<Uniform>( "Uniform" )
    .constructor<double,double>()
    .field( "min", &Uniform::min )
    .field( "max", &Uniform::max )
    .method( "draw", &Uniform::draw )
    .method( "range", &uniformRange )
    ;
}



// Equlibrium Model Class for Age-size-sex structured model.
class Equilibrium
{
private:
	int A;
	int G;
	int S;

	double m_phiE;
	double m_kap;
	double m_ro;

	IntegerVector dim;
	NumericVector age;
	IntegerVector grp;
	IntegerVector sex;

	NumericVector m_la;
	NumericVector m_sa;
	NumericVector m_fa;
	NumericVector m_wa;
	NumericVector m_M;
	NumericVector m_va;
	NumericVector m_sc;
	NumericVector m_sr;
	NumericVector m_sd;
	NumericVector m_vd;
	NumericVector m_pg;

	List m_stock;
public:
	Equilibrium(List stock_);
	~Equilibrium(){}

	List calcLifeTable(List &stock);
	void calcSelectivities(List procedure);
	void calcEquilibrium(double fe = 0);
	
	List get_stock()       { return m_stock; }
	void set_stock(List x_){ m_stock = x_;   }

	NumericVector calcPage(NumericVector la, NumericVector sa, NumericVector pl, NumericVector xl);

};

RCPP_MODULE(equilibrium_module)
{
	class_<Equilibrium>( "Equilibrium" )
	.constructor<List>()
	.property( "m_stock", &Equilibrium::get_stock, &Equilibrium::set_stock )
	.method( "calcLifeTable", &Equilibrium::calcLifeTable )
	.method( "calcSelectivities", &Equilibrium::calcSelectivities )
	.method( "get_stock",&Equilibrium::get_stock )
	.method( "calcEquilibrium",&Equilibrium::calcEquilibrium)
	;
}

void Equilibrium::calcEquilibrium(double fe)
{
	/*
	Psuedocode:
	1. calculate age-specific mortlaity
	2. calculate survivorship if fe > 0
	3. calculate equilirbium recruitment & ssb
	4. calculate ypr,spr,ye,de etc.
	5. calculate other metrics (average weight-at-age)
	*/
	int n = A*G*S;
	NumericVector za(n);
	NumericVector sa(n);
	NumericVector qa(n);
	NumericVector da(n);
	NumericVector pa(n);
	NumericVector ua(n);
	NumericVector ta(n);
	NumericVector lz(n);

	int ii = -1;
	for (IntegerVector::iterator h = sex.begin(); h != sex.end(); ++h)
	{
		for (IntegerVector::iterator g = grp.begin(); g != grp.end(); ++g)
		{
			for (NumericVector::iterator i = age.begin(); i != age.end(); ++i)
			{
				++ii;
				za[ii] = m_M[*h] + fe*m_va[ii]; // add bycatch fd
				sa[ii] = exp(-za[ii]);
				ua[ii] =  m_sc[ii]           * (1.-sa[ii])/za[ii] * m_pg[*g];
				qa[ii] = (m_sc[ii]*m_sr[ii]) * (1.-sa[ii])/za[ii] * m_pg[*g];
				da[ii] = (m_sc[ii]*m_sd[ii]) * (1.-sa[ii])/za[ii] * m_pg[*g]; 

				// survivorship under fished conditions
				if( i==age.begin() )
				{
					lz[ii] = 1.0;
				}
				else
				{
					lz[ii] = lz[ii-1] * exp(-za[ii-1]);
				}
			}
			lz[ii] = lz[ii]/(1.-exp(-za[ii]));
		}
	}

	// Fished SSB per recruit (phiE)
	double phie = 0;
	for (int ii = 0; ii < A*G*S; ++ii)
	{
		phie += lz[ii]*m_fa[ii];
	}

	// Equilibrium recruitment
	double t1 = m_phiE/phie;
	double t2 = (m_kap -t1);
	double re,be;
	t2 > 0 ? re = m_ro*t2/(m_kap-1.0) : re = 0.0;
	be = re * phie;


	Rcpp::Rcout<<"Fe = "<<fe<<std::endl;
	Rcpp::Rcout<<"Re = "<<re<<std::endl;

	// Yield per recruit, etc.
	double ye = 0;
	for (int ii = 0; ii < n; ++ii)
	{
		ye += re*fe*lz[ii]*m_wa[ii]*qa[ii];
	}

	Rcpp::Rcout<<"Ye = "<<ye<<std::endl;

}

NumericVector Equilibrium::calcPage(NumericVector la, NumericVector sa, NumericVector pl, NumericVector xl)
{
	int A = la.size();
	int L = xl.size();
	double hbw = 0.5*(xl(2)-xl(1));
	NumericMatrix ALK(A,L);
	NumericVector tva(A);
	// Rcpp::Rcout<<A<<std::endl;
	// ALK = sapply(xl+hbw,pnorm,la,sa)-- sapply(xl-hbw,pnorm,mean=la,sd=sa);
	for (int i = 0; i < A; ++i)
	{
		double mu = la(i);
		double sd = sa(i);
		for (int j = 0; j < L; ++j)
		{
			double ub = xl(j)+hbw;
			double lb = xl(j)-hbw;
	
			ALK(i,j) = R::pnorm(ub,mu,sd,true,false)-R::pnorm(lb,mu,sd,true,false);
			tva(i)  += pl(j) * ALK(i,j);
		}
	}

	m_stock["ALK"] = ALK;
	m_stock["tva"] = tva;

	return(tva);
}

Equilibrium::Equilibrium(List stock_)
: m_stock(stock_)
{
	List calcLifeTable(m_stock);
}

List Equilibrium::calcLifeTable(List &stock)
{
	List out=clone(stock);
	
	// Model dimensions
	A   = as<int>(stock["A"]);
	G   = as<int>(stock["G"]);
	S   = as<int>(stock["S"]);
	dim = as<IntegerVector>(stock["dim"]);
	age = as<NumericVector>(stock["age"]);
	grp = seq(0,G-1);
	sex = seq(0,S-1);
	// Rcpp::Rcout<<dim<<std::endl;

	// Population parameters
	double bo          = as<double>(stock["bo"]);
	double  h          = as<double>(stock["h"]);
	NumericVector m    = as<NumericVector>(stock["m"]);
	NumericVector linf = as<NumericVector>(stock["linf"]);
	NumericVector vonk = as<NumericVector>(stock["vonk"]);
	NumericVector to   = as<NumericVector>(stock["to"]);
	NumericVector p    = as<NumericVector>(stock["p"]);
	NumericVector cv   = as<NumericVector>(stock["cv"]);
	NumericVector a50  = as<NumericVector>(stock["a50"]);
	NumericVector k50  = as<NumericVector>(stock["k50"]);
	NumericVector a    = as<NumericVector>(stock["a"]);
	NumericVector b    = as<NumericVector>(stock["b"]);
	NumericVector pg   = as<NumericVector>(stock["pg"]);
	NumericVector dev  = as<NumericVector>(stock["dev"]);
	

	// Age-schedule information
	NumericVector lx(A*G*S);    lx.attr("dim")    = dim;
	NumericVector la(A*G*S);    la.attr("dim")    = dim;
	NumericVector wa(A*G*S);    wa.attr("dim")    = dim;
	NumericVector fa(A*G*S);    fa.attr("dim")    = dim;
	NumericVector sd_la(A*G*S); sd_la.attr("dim") = dim;
	NumericVector mu,sigma;


	int ii = -1;
	for (IntegerVector::iterator h = sex.begin(); h != sex.end(); ++h)
	{
		// Mean Length -at- age
		NumericVector ma = plogis(age,a50[*h],k50[*h]);
		mu    = gvonb_cpp(age,linf[*h],vonk[*h],to[*h],p[*h]);
		sigma = cv[*h] * mu;

		for (IntegerVector::iterator g = grp.begin(); g != grp.end(); ++g)
		{
			for (NumericVector::iterator i = age.begin(); i != age.end(); ++i)
			{
				++ii;
				lx[ii]    = pow(exp(-m[*h]), *i - 1.0);
				la[ii]    = mu[*i-1] + dev[*g]*sigma[*i-1];
				sd_la[ii] = sqrt(1./G* pow(cv[*h]*mu[*i-1],2.0) );
				wa[ii]    = a[*h]* pow(la[ii],b[*h]);
				fa[ii]    = ma[*i-1] * wa[ii] * pg[*g];
			}
			lx[ii] = lx[ii] / (1.0 - exp(-m[*h]));
		}
	}

	// Unfished SSB per recruit (phiE)
	double phiE = 0;
	for (int ii = 0; ii < A*G*S; ++ii)
	{
		phiE += lx[ii]*fa[ii];
	}
	// Rcpp::Rcout<<"Phie from Halitosis.cpp"<<std::endl;
	// Rcpp::Rcout<<phiE<<std::endl;
	// Stock-recruitment parameters


	out["lx"]    = lx;
	out["la"]    = la;
	out["sd_la"] = sd_la;
	out["wa"]    = wa;
	out["fa"]    = fa;
	
	m_M  = m;
	m_la = la;
	m_sa = sd_la;
	m_fa = fa;
	m_wa = wa;
	m_pg = pg;
	m_phiE = phiE;
	m_kap  = 4.*h/(1.-h);
	m_ro   = bo/phiE;
	Rcpp::Rcout<<"Ro = "<<m_ro<<std::endl;

	m_stock["la"]   = la;
	m_stock["phiE"] = phiE;
	m_stock["ro"]   = m_ro;
	m_stock["kap"]  = m_kap;
	return(out);
}

void Equilibrium::calcSelectivities(List procedure)
{
	// Calculate capture probabilties:
	// sc = P(size at capture)
	// sr = P(size at retention)
	// sd = P(size at discard)
	// va = P(retained mortality) = sc*(sr+sd*DMR)
	// vd = P(size at bycatch)
	// Rcpp::Rcout<<"calcSelectivities"<<std::endl;
	
	// Rcpp::Rcout<<dim<<std::endl;
	// IntegerVector dim = as<IntegerVector>(stock["dim"]);
	NumericVector sc(A*G*S);    
	NumericVector sr(A*G*S);    
	NumericVector sd(A*G*S);    
	NumericVector va(A*G*S);    va.attr("dim")    = dim;
	NumericVector vd(A*G*S);    vd.attr("dim")    = dim;

	// // Compute selectivities for each array element.
	double s50 = as<double>(procedure["selex_50"]);
	double s95 = as<double>(procedure["selex_95"]);
	double dmr = as<double>(procedure["dmr"]);
	double slim = as<double>(procedure["slim"]);
	double ulim = as<double>(procedure["ulim"]);
	double selex_bycatch50 = as<double>(procedure["selex_bycatch50"]);
	double selex_bycatch95 = as<double>(procedure["selex_bycatch95"]);
	double selex_asymptote = as<double>(procedure["selex_asymptote"]);

	NumericVector xl = as<NumericVector>(procedure["mid_points"]);
	NumericVector pl = plogis95_cpp(xl,s50,s95);
	NumericVector pr = plogis95_cpp(xl,slim,1.01*slim) - plogis95_cpp(xl,ulim,1.01*ulim);
	NumericVector pd = plogis95_cpp(xl,selex_bycatch50,selex_bycatch95) - (1.-selex_asymptote)*plogis95_cpp(xl,100.3,5.0);

	// Capture
	sc = calcPage(m_la,m_sa,pl,xl);
	sc.attr("dim") = dim;

	// Retention
	sr = calcPage(m_la,m_sa,pr,xl);
	sr.attr("dim") = dim;

	// Discard
	sd = 1.0 - sr;
	sd.attr("dim") = dim;

	// Directed fishery mortality
	va = sc * (sr + sd*dmr);
	va.attr("dim") = dim;

	// Bycatch
	vd = calcPage(m_la,m_sa,pd,xl);
	vd.attr("dim")    = dim;

	m_va = va;
	m_sc = sc;
	m_sr = sr;
	m_sd = sd;
	m_vd = vd;

	m_stock["pl"] = pl;
	m_stock["sc"] = sc;
	m_stock["sr"] = sr;
	m_stock["sd"] = sd;
	m_stock["va"] = va;
	m_stock["vd"] = vd;
	
}








// // [[Rcpp::export]]
// NumericVector gvonb_cpp (IntegerVector t, double linf, double vbk, double to, double p)
// {
// 	NumericVector l = linf * pow((1.0 - exp(-vbk*(t - to))),p);
				  
// 	return(l);
// }

// // [[Rcpp::export]]
// List phart (List stock)
// {
// 	List out=clone(stock);
	
// 	// Model dimensions
// 	int A             = as<int>(stock["A"]);
// 	int G             = as<int>(stock["G"]);
// 	int S             = as<int>(stock["S"]);
// 	IntegerVector dim = as<IntegerVector>(stock["dim"]);
// 	NumericVector age = as<NumericVector>(stock["age"]);
// 	IntegerVector grp = seq(0,G-1);
// 	IntegerVector sex = seq(0,S-1);

// 	// Population parameters
// 	double bo          = as<double>(stock["bo"]);
// 	double  h          = as<double>(stock["h"]);
// 	NumericVector m    = as<NumericVector>(stock["m"]);
// 	NumericVector linf = as<NumericVector>(stock["linf"]);
// 	NumericVector vonk = as<NumericVector>(stock["vonk"]);
// 	NumericVector to   = as<NumericVector>(stock["to"]);
// 	NumericVector p    = as<NumericVector>(stock["p"]);
// 	NumericVector cv   = as<NumericVector>(stock["cv"]);
// 	NumericVector a50  = as<NumericVector>(stock["a50"]);
// 	NumericVector k50  = as<NumericVector>(stock["k50"]);
// 	NumericVector a    = as<NumericVector>(stock["a"]);
// 	NumericVector b    = as<NumericVector>(stock["b"]);
// 	NumericVector pg   = as<NumericVector>(stock["pg"]);
// 	NumericVector dev  = as<NumericVector>(stock["dev"]);
	

// 	// Age-schedule information
// 	NumericVector lx(A*G*S);    lx.attr("dim")    = dim;
// 	NumericVector la(A*G*S);    la.attr("dim")    = dim;
// 	NumericVector sd_la(A*G*S); sd_la.attr("dim") = dim;
// 	NumericVector wa(A*G*S);    wa.attr("dim")    = dim;
// 	NumericVector fa(A*G*S);    fa.attr("dim")    = dim;
// 	NumericVector mu,sigma;
// 	NumericVector ma = plogis(age,a50,k50);

// 	int ii = -1;
// 	for (IntegerVector::iterator h = sex.begin(); h != sex.end(); ++h)
// 	{
// 		// Mean Length -at- age
// 		mu    = gvonb_cpp(age,linf[*h],vonk[*h],to[*h],p[*h]);
// 		sigma = cv[*h] * mu;

// 		for (IntegerVector::iterator g = grp.begin(); g != grp.end(); ++g)
// 		{
// 			for (NumericVector::iterator i = age.begin(); i != age.end(); ++i)
// 			{
// 				ii++;
// 				lx[ii]    = pow(exp(-m[*h]), *i - 1.0);
// 				la[ii]    = mu[*i-1] + dev[*g]*sigma[*i-1];
// 				sd_la[ii] = sqrt(1./G* pow(cv[*h]*mu[*i-1],2.0) );
// 				wa[ii]    = a[*h]* pow(la[ii],b[*h]);
// 				fa[ii]    = ma[*i-1] * wa[ii];
// 			}
// 			lx[ii] = lx[ii] / (1.0 - exp(-m[*h]));
// 		}
// 	}


// 	out["lx"]    = lx;
// 	out["la"]    = la;
// 	out["sd_la"] = sd_la;
// 	out["wa"]    = wa;
// 	out["fa"]    = fa;
	
// 	return(out);
// }