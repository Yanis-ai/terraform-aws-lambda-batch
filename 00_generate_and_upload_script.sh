#!/bin/bash
# 生成1000个1MB大小的随机文件，每100个打包成一个 tar.gz 文件

mkdir -p ./testfiles

for ((i=1; i<=1000; i++))
do
  head -c 1M /dev/urandom > "test_file_$i.txt"

  if (( $i % 100 == 0 ))
  then
    archive_name="test_files_${i}_$(($i-99)).tar.gz"
    file_list=$(seq -f "test_file_%g.txt" $(($i-99)) $i)
    tar -czvf "./testfiles/$archive_name" $file_list
    rm $file_list
  fi
done
