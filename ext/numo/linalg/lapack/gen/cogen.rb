#! /usr/bin/env ruby

pwd = File.dirname(__FILE__)
#libpath = File.absolute_path(File.dirname(__FILE__))+"/../../../../lib"
#$LOAD_PATH.unshift libpath

require_relative "../../blas/gen/decl"

while true
  if ARGV[0] == "-l"
    require "erbpp/line_number"
    ARGV.shift
  elsif ARGV[0] == "-o"
    ARGV.shift
    $output = ARGV.shift
    require "fileutils"
    FileUtils.rm_f($output)
  else
    break
  end
end

if ARGV.size != 1
  puts "usage:\n  ruby #{$0} [-l] blas_char"
  exit 1
end

blas_char = ARGV[0]

erb_dir = ["../tmpl"]
erb_dir.map!{|d| File.join(pwd,d)}

code = DefLib.new do
  set erb_dir: erb_dir
  set erb_suffix: ".c"
  set ns_var: "mN"

  set file_name: $output || ""
  #set include_files: ["numo/types/#{type_name}.h"]
  set lib_name: "numo_linalg_lapack_"+blas_char

  def_module do
    mname = "Linalg"
    mbase = mname.downcase
    set name: mbase
    set module_name: mname
    set module_var: "m"+mname
    set full_module_name: "Numo::"+mname

    def_module do
      extend Decl
      name = "Lapack"
      base = name.downcase
      set ns_var: "m"+mname
      set name: base
      set module_name: name
      set module_var: "m"+name
      set full_module_name: "Numo::Linalg::"+name
      set module_desc: eval(File.read(File.join(pwd,"desc.rb")))

      DefError.new(self,"LapackError","rb_eStandardError");

      ErbPP.new(self,"def_"+blas_char)
      set blas_char: blas_char
      eval File.read(File.join(pwd,"spec.rb")), binding, "spec.rb"
    end
  end
end.result

if $output
  open($output,"w").write(code)
else
  $stdout.write(code)
end
