require 'mkmf'
require 'numo/narray'
require 'erb'

ldirs = [
 dir_config("mkl")[1],
 dir_config("openblas")[1],
 dir_config("atlas")[1],
 dir_config("blas")[1],
 dir_config("lapack")[1],
]
bked = with_config("backend")

FileUtils.mkdir_p "lib"
open("lib/site_conf.rb","w"){|f| f.write "
module Numo
  module Linalg
    BACKEND = #{bked.inspect}
    MKL_LIBPATH = #{ldirs[0].inspect}
    OPENBLAS_LIBPATH = #{ldirs[1].inspect}
    ATLAS_LIBPATH = #{ldirs[2].inspect}
    BLAS_LIBPATH = #{ldirs[3].inspect}
    LAPACK_LIBPATH = #{ldirs[4].inspect}
  end
end"}

$LOAD_PATH.each do |x|
  if File.exist? File.join(x,'numo/numo/narray.h')
    $INCFLAGS = "-I#{x}/numo " + $INCFLAGS
    break
  end
end

srcs = %w(
blas
blas_s
blas_d
blas_c
blas_z
)
$objs = srcs.collect{|i| i+".o"}

if !have_header('numo/narray.h')
  puts "
  Header numo/narray.h was not found. Give pathname as follows:
  % ruby extconf.rb --with-narray-include=narray_h_dir"
  exit(1)
end

if have_header("dlfcn.h")
  exit(1) unless have_library("dl")
  exit(1) unless have_func("dlopen")
elsif have_header("windows.h")
  exit(1) unless have_func("LoadLibrary")
end

dep_path = File.join(__dir__, "depend")
File.open(dep_path, "w") do |dep|
  dep_erb_path = File.join(__dir__, "depend.erb")
  File.open(dep_erb_path, "r") do |dep_erb|
    erb = ERB.new(dep_erb.read)
    erb.filename = dep_erb_path
    dep.print(erb.result)
  end
end

create_makefile('numo/linalg/blas')
