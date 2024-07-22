#####################################################
# Sample script for CON prediction from SMILES
# Author : Allan Sauvat, INSERM UMR1138, Team Kroemer
# Version : 07/19/25
#####################################################

#==========================================================================================================================#
# Required packages
#==========================================================================================================================#

library(tensorflow)
library(keras)
tf$print('tf initialized')
#
library(rcdk)
#
library(magrittr)
library(pbapply)
library(doParallel)

#==========================================================================================================================#
# IMPORT SMILES AND COMPUTE DESCRIPTORS
#==========================================================================================================================#

#-------------------------------------------------------------------------------
smi = c('C1=CC(=C2C(=C1NCCNCCO)C(=O)C3=C(C=CC(=C3C2=O)O)O)NCCNCCO',  #Canonical SMILES
        'CC1C=CC=C(C(=O)NC2=C(C(=C3C(=C2O)C(=C(C4=C3C(=O)C(O4)(OC=CC(C(C(C(C(C(C1O)C)O)C)OC(=O)C)C)OC)C)C)O)O)C=NN5CCN(CC5)C)C',
        'CC1OCC2C(O1)C(C(C(O2)OC3C4COC(=O)C4C(C5=CC6=C(C=C35)OCO6)C7=CC(=C(C(=C7)OC)O)OC)O)O')
names(smi) = c('MITOXANTRONE','RIFAMPIN','ETOPOSIDE')
#-------------------------------------------------------------------------------
dn = sapply(get.desc.categories(), get.desc.names)%>%unlist()%>%unique() #get CDK categories

#-------------------------------------------------------------------------------
# Compute descriptors in safe multithreaded env.
cl = makeCluster(detectCores(),type='SOCK')
clusterExport(cl,c('dn'))
dsc = pblapply(smi,function(smk){
  library(rcdk);library(magrittr)
  #
  dsci = data.frame(XLogP=NA,MW=NA) #initialize
  myparser = get.smiles.parser()
  try({
    molk = parse.smiles(smk,smiles.parser = myparser)[[1]] %>% generate.2d.coordinates() %>% get.largest.component() # parse & clean smiles
    mwk = get.exact.mass(molk) # compute molecular weight for filtering
    if(mwk<1500){ #arbitrary threshold, above is not "small molecule"
      dsci = eval.desc(molk,dn)
    }
  },silent = TRUE)
  return(dsci)
},cl = cl)
stopCluster(cl);rm(cl)

#-------------------------------------------------------------------------------
# Bind vectors list
cnm = pblapply(dsc,function(x)colnames(x)) %>% unlist() %>% unique()
rn = names(dsc)
#
cl = makeCluster(detectCores(),type='SOCK'); clusterExport(cl,'cnm');registerDoParallel(cl)
dsc = foreach(dsci=dsc,.combine = rbind) %dopar% {
  y = rep(NA,length(cnm));names(y)=cnm
  for(s in colnames(dsci)){
    y[s] = dsci[,s]
  }
  return(y)
}
stopCluster(cl);rm(cl)
rownames(dsc) = rn; rm(rn)

#==========================================================================================================================#
# NORMALIZE TENSOR and predict CON probabilities
#==========================================================================================================================#

#-------------------------------------------------------------------------------
#Prepare tensor from descriptors
vnorm = readRDS('../MODEL/vnorm.Rds')
#
preproc = function(x){
  rn.bk = rownames(x)
  y = apply(x[,colnames(vnorm)],2,as.numeric)
  if(is.null(nrow(y))){cn.bk = names(y);y = matrix(y, nrow=1);colnames(y)=cn.bk}
  rownames(y)=rn.bk
  for(nm in colnames(y)){
    y[,nm][is.na(y[,nm])] = vnorm['med',nm]
    y[,nm] = (y[,nm]-vnorm['min',nm])/(vnorm['max',nm]-vnorm['min',nm])
  };rm(nm)
  y = as.matrix(y)
  return(y)
}
#
tsr = preproc(dsc)

#-------------------------------------------------------------------------------
# Load CNN and predict
tf_mod = load_model_hdf5('../MODEL/CO3N.h5', compile=F)
predv = predict(tf_mod,tsr,verbose=0L);rownames(predv)=rownames(tsr)
#
print(predv) #display results


