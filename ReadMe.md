![CON_MICRO](https://github.com/user-attachments/assets/293e6444-d11c-4a10-9e80-00fe0f4d421c)
# NucleolAI
The *NucleolAI* project integrates resources to develop and utilize deep neural network-based QSAR models capable of predicting a small molecule's potential to induce nucleolar compaction (referred as *Condensation Of Nucleoli*, *CON*) in cell nuclei from its SMILES notation.

## OS environment
Available data sets can be parsed without specific programming skills. Free software [7zip](https://www.7-zip.org/) is required to uncompress the NIH 320K data set. Minimal scripting using R will be required to exploit the QSAR model. Notably, [R](https://cran.r-project.org/),  [Java](https://www.java.com/fr/) & [RStudio](https://www.rstudio.com/products/rstudio/download/) (optional) will have to be installed.

In a Debian environment :
```sh
sudo apt install r-base default-jdk
```
## R environment

### Packages
The following packages are required for exploiting the tools at disposal. Within an R session :
```R
install.packages(c('rJava','rcdk','tensorflow','reticulate','keras','magrittr','pbapply','doParallel'))
```
### Dependencies
The code below must be run only once, for installing & configuring [TensorFlow](https://www.tensorflow.org/):
```R
library(tensorflow)
library(keras)
#
install_tensorflow()
install_keras()
```
If required, R will prompt the user for installing dependencies (as the tensorflow package depends on Python interpreter)

## Files description

| File |Description |
|--|--|
|MODEL/CO3N.h5|Pre-trained tensorflow DNN for CON prediction|
|MODEL/vnorm.Rds|R table for CDK descriptors normalization|
|RESOURCES/training_set.csv|Training set containing labels and precomputed CDK descriptors|
|RESOURCES/validation_set.csv|Validation set containing labels and precomputed CDK descriptors|
|RESOURCES/NIH_320K.7z| Compressed NIH-DTP chemical dataset, with CDK descriptors and CON prediction results|
|RESOURCES/Running_example.R| Script for predicting CON from SMILES characters using pretrained DNN model 




