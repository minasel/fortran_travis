#!/bin/sh
./gdrive download 0BwU9d5SH6pPQRTFiT0FHUVl3aVk
brew update

if [ -f "brew_cache.tar.gz" ]; then
  echo "Found Brew Cache, linking"
  tar zxf brew_cache.tar.gz --directory /usr/local/Cellar
  brew link open-mpi gmp libmpc isl gcc || brew install open-mpi
  brew link fftw || brew install fftw --with-fortran
  brew link szip hdf5 netcdf || brew tap homebrew/science && brew install netcdf --with-fortran 
else
  echo "Did not find Brew Cache, download and reinstall"
  brew install open-mpi 
  brew install fftw --with-fortran
  brew tap homebrew/science
  brew install netcdf --with-fortran
  echo "*****************************************************************"
  brew info --installed
  echo "*****************************************************************"
  echo "*****************************************************************"
fi
tar czf brew_cache.tar.gz --directory /usr/local/Cellar gmp libmpc isl gcc szip hdf5 open-mpi fftw netcdf
./gdrive upload brew_cache.tar.gz 

