#!/bin/bash

exec ab -n 25000 -c 10 "http://rails.think/cpu_bound?number=28"
# exec ab -n 25000 -c 10 "http://rails.think/io_bound"




