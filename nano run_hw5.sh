#!/bin/bash

set -e  # stop on error


echo "Pulling repo..."
git pull

echo "Going up one directory..."
cd ..

echo "Moving file..."
mv contuniation_of_digital_testing/homework05/top_verichip5.sv .

echo "Running simulation..."
make simv_verichip.log

echo "Submitting..."
../submit

echo "Done "