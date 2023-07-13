#! /bin/env tclsh
set enable_prelayout_timing 1
set working_dir [exec pwd]
set vsd_array_length [llength [split [lindex $argv 0] ,]]
set input [lindex [split [lindex $argv 0] ,] $vsd_array_length-1]
#if {! [regexp {^csv} $input] || $argc != 1 } {
 #       puts "Error in Usage"
  #      puts "Usage ./vsyndth <.csv>"
   #     puts "where <.csv> file has below inputs"
    #    } else {
#set x [regexp {csv+} $input]
#puts "value $x"
#set y [expr ($argc!=1)]
#puts "value $y"
#if {![regexp {csv+} $input] || $argc!= 1 } {
#        puts "Error in Usage"
#        puts "Usage ./vsyndth <.csv>"
#        puts "where <.csv> file has below inputs"
#        } else {
puts  "-------------------------------------------------------------"
puts  "Day2 : creating variables and Convert all inputs to SDC format"
puts "============================================================="
puts "1.Creating Variable"
puts "*******************"
set des_file [lindex $argv 0]
package require csv
package require struct::matrix
struct::matrix m
set fp [open $des_file]
csv::read2matrix $fp m , auto
close $fp
set col [m columns]
m add columns $col
m link my_arr
set num_of_rows [ m rows]
puts "No. of ROWs $num_of_rows"
set i 0
while {$i < $num_of_rows} {
puts "\n INFO :Setting $my_arr(0,$i) as '$my_arr(1,$i)'"
if {$i == 0} {
set [ string map {" " ""} $my_arr(0,$i)] $my_arr(1,$i)
} else {
set [string map {" " ""} $my_arr(0,$i)] [file normalize $my_arr(1,$i)]
}
set i [expr {$i+1}]
}
#}

puts "INFO: Initial User Variables for further reference"
puts "DesignName = $DesignName"
puts "OutputDirectory= $OutputDirectory"
puts "NetlistDirectory = $NetlistDirectory"
puts "EarlyLibraryPath = $EarlyLibraryPath"
puts "LateLibraryPath = $LateLibraryPath"
puts "ConstraintsFile = $ConstraintsFile"

puts "\n\n2.checking the directories and files mentioned existed or not"
puts "******************************************************************"
if {! [file exists $EarlyLibraryPath] } {
	puts "\n Error: Couldnt find the EarlyLibrary cell in path $EarlyLibraryPath. Exiting...."
	exit
} else { 
	puts "\n INFO:Early Library cell is present in path $EarlyLibraryPath."
}
if {! [file exists $LateLibraryPath] } {
        puts "\n Error: Couldnt find the Late Library cell in path $LateLibraryPath. Exiting...."
        exit
} else {
         puts "\n INFO:Late Library cell is present in path $LateLibraryPath."
}
if {! [file isdirectory $OutputDirectory] } {
        puts "\n Error: Couldnt find the Output Directory in path $OutputDirectory. creating $OutputDirectory...."
	file mkdir $OutputDirectory
        exit
} else {
        puts "\n INFO:Output Directory is found in path $OutputDirectory."
}
if {! [file isdirectory $NetlistDirectory] } {
        puts "\n Error: Couldnt find the Netlist Directory in path $OutputDirectory.Exiting...."
        file mkdir $NetlistDirectory
        exit
} else {
        puts "\n INFO:Netlist Directory is found in path $NetlistDirectory."
}
if {! [file exists $ConstraintsFile] } {
        puts "\n Error: Couldnt find the Constraints File in path $ConstraintsFile. Exiting...."
        exit
} else {
        puts "\n INFO:Constraints File is present in path $ConstraintsFile."
}

puts " \n\n DAY 3"
puts "------------------"
puts "\n\n3. Creating SDC format"
puts "***************************"

puts "\n Info : Dumping SDC constraints for $DesignName"
::struct::matrix constraints
set chan [open $ConstraintsFile]
csv::read2matrix $chan constraints , auto
close $chan
set number_of_rows [constraints rows]
set number_of_columns [constraints columns]
puts "num_of rows : $number_of_rows"
puts "num of columns : $number_of_columns"
set clock_start [lindex [lindex [constraints search all CLOCKS] 0] 1]
set clock_start_column [lindex [lindex [constraints search all CLOCKS] 0] 0]
set input_ports_start [lindex [lindex [constraints search all INPUTS] 0] 1]
set output_ports_start [lindex [lindex [constraints search all OUTPUTS] 0] 1]
# clock transition constraints
set clock_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] early_rise_delay] 0] 0]
set clock_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] early_fall_delay] 0] 0]
set clock_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] late_rise_delay] 0] 0]
set clock_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] late_fall_delay] 0] 0]
# clock transition constraints
set clock_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] early_rise_slew] 0] 0]
set clock_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] early_fall_slew] 0] 0]
set clock_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] late_rise_slew] 0] 0]
set clock_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] late_fall_slew] 0] 0]
# Creating Constraint file
set sdc_file [open $OutputDirectory/$DesignName.sdc "w"]
set i [expr {$clock_start+1}]
set end_of_ports [expr {$input_ports_start-1}]
puts "\n INFO -SDC: working on clock constraints....."
while {$i < $end_of_ports} {
	puts -nonewline $sdc_file "\ncreate_clock -name [constraints get cell 0 $i] -period [constraints get cell 1 $i] -waveform \{0 [expr {[constraints get cell 1 $i]*[constraints get cell 2 $i]/100}]\} \[get_ports [constraints get cell 0 $i]\]"
puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [constraints get cell $clock_early_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [constraints get cell $clock_early_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [constraints get cell $clock_late_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [constraints get cell $clock_late_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
puts -nonewline $sdc_file "\nset_clock_transition -rise -min [constraints get cell $clock_early_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
puts -nonewline $sdc_file "\nset_clock_transition -fall -min [constraints get cell $clock_early_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
puts -nonewline $sdc_file "\nset_clock_transition -rise -max [constraints get cell $clock_late_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
puts -nonewline $sdc_file "\nset_clock_transition -fall -min [constraints get cell $clock_late_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
set i [expr {$i +1}]
}
#INPUT Constraints processing
set input_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] early_rise_delay] 0] 0]
set input_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] early_fall_delay] 0] 0]
set input_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] late_rise_delay] 0] 0]
set input_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] late_fall_delay] 0] 0]
# input  transition constraints
set input_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] early_rise_slew] 0] 0]
set input_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] early_fall_slew] 0] 0]
set input_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] late_rise_slew] 0] 0]
set input_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] late_fall_slew] 0] 0]




#set input_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] early_rise_slew] 0] 0]
#set input_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] early_fall_slew] 0] 0]
#set input_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] late_rise_slew] 0] 0]
#set input_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] late_fall_slew] 0] 0]

set related_clock [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns -1}] [expr {$output_ports_start -1}] clocks ] 0] 0]
set i [expr {$input_ports_start +1}]
set end_of_ports [expr {$output_ports_start -1}]
puts "input port start $i"
puts "\nINFO-SDC : Working on IO Constraints "
puts "\nINFO-SDC : Categorizing Input ports as Bit and Bus"
puts "endof  port start $end_of_ports"

while {$i < $end_of_ports} {
	set netlist [glob -dir $NetlistDirectory *.v]
#	puts "netlist ------------  $netlist "
	set tmp_file [open /home/vsduser/vsdsynth/tmp/1 w]
	foreach f $netlist {
		set fp [open $f]
#		puts "Reading file $f"
		while {[gets $fp line] != -1} {
			set pattern1 " [constraints get cell 0 $i];"
			if {[regexp -all -- $pattern1 $line]} {
		#		puts "pattern11 \"$pattern1\" found and matching in verilog file \"$f\" is \"$line\""
				set pattern2 [lindex [split $line ";"] 0]
		#		puts "Creating pattern2 \"$pattern2\" by spliting the pattern1 by semicolon as delimiter"
				if {[regexp -all {input} [lindex [split $pattern2 "\S+"] 0]]} {
		#			puts "From the patterns matching \"$pattern2\" is selected as it gives the proper matched string"
					set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
		#			puts "Printing first 3 elements of pattern2 as \"$s1\" using space as delimiter"
					puts -nonewline $tmp_file "\n[regsub -all {\S+} $s1 " "]"
					puts "Replacing multiple space in the s1 as single space and reformat as \"[regsub -all {\s+} $s1 " "]\""
				}
			}
		}
		close $fp
	}
close $tmp_file
set tmp_file [open /home/vsduser/vsdsynth/tmp/1 r]
#puts "Reading [read $tmp_file]"
#puts "Reading /tmp/1 file as [split [read $tmp_file] \n]"
#puts "sorting /tmp/1 contents as [lsort -unique [split [read $tmp_file] \n]]"
#puts "joining /tmp/1 as [join [lsort -unique [split [read $tmp_file] \n]] \n]"
set tmp2_file [open /home/vsduser/vsdsynth/tmp/2  w]
puts -nonewline $tmp2_file "[join [lsort -unique [split [read $tmp_file] \n]] \n]"
close $tmp_file
close $tmp2_file
set tmp2_file [open /home/vsduser/vsdsynth/tmp/2 r]
puts "^^^^^INPUT   ^^^^^^^^^^^^^^^^^^^^^^^"
puts "count is [read $tmp2_file] "
set count [llength [read $tmp2_file]]
puts "splitting content of tmp2_file using space and counting number of elements as $count "
if {$count > 2} {
	set inp_ports [concat [constraints get cell 0 $i]*]
	puts "bussed"
} else {
	set inp_ports [constraints get cell 0 $i]
	puts "not bussed"
}
puts "inputs port name is $inp_ports since count is $count"
puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_delay_start $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_delay_start $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_delay_start $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_delay_start $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_slew_start $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_slew_start $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_slew_start $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_slew_start $i] \[get_ports $inp_ports\]"
set i [expr {$i+1}]
}
close $tmp2_file

puts "**************************************************"
puts "			DAY 4				"
puts "**************************************************"

puts "\nOUTPUT port with delay and load constraints"
puts "----------------------------------------------"

set output_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns -1}] [expr {$number_of_rows -1}] early_rise_delay] 0] 0]
set output_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns -1}] [expr {$number_of_rows -1}] early_fall_delay] 0] 0]
set output_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns -1}] [expr {$number_of_rows -1}] late_rise_delay] 0] 0]
set output_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns -1}] [expr {$number_of_rows -1}] late_fall_delay] 0] 0]
# input  transition constraints
set output_load_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns -1}] [expr {$number_of_rows -1}] load] 0] 0]
#set output_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns -1}] [expr {$number_of_rows -1}] early_fall_slew] 0] 0]
#set output_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns -1}] [expr {$number_of_rows -1}] late_rise_slew] 0] 0]
#set output_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns -1}] [expr {$number_of_rows -1}] late_fall_slew] 0] 0]


set related_clock [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns -1}] [expr {$number_of_rows -1}] clocks ] 0] 0]
set i [expr {$output_ports_start +1}]
set end_of_ports [expr {$number_of_rows -1}]

puts "output port start $i"
puts "\nINFO-SDC : Working on IO Constraints "
puts "\nINFO-SDC : Categorizing OUTput ports as Bit and Bus"
puts "endof  port start $end_of_ports"

while {$i < $end_of_ports} {
        set netlist [glob -dir $NetlistDirectory *.v]
        set tmp_file [open /home/vsduser/vsdsynth/tmp/1 w]
        foreach f $netlist {
                set fp [open $f]
  #              puts "Reading file $f"
                while {[gets $fp line] != -1} {
                        set pattern1 " [constraints get cell 0 $i];"
                        if {[regexp -all -- $pattern1 $line]} {
 #                               puts "pattern11 \"$pattern1\" found and matching in verilog file \"$f\" is \"$line\""
                                set pattern2 [lindex [split $line ";"] 0]
#                                puts "Creating pattern2 \"$pattern2\" by spliting the pattern1 by semicolon as delimiter"
                                if {[regexp -all {output} [lindex [split $pattern2 "\S+"] 0]]} {
                                        #puts "From the patterns matching \"$pattern2\" is selected as it gives the proper matched string"
                                        set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
                                       # puts "Printing first 3 elements of pattern2 as \"$s1\" using space as delimiter"
                                        puts -nonewline $tmp_file "\n[regsub -all {\S+} $s1 " "]"
                                        puts "Replacing multiple space in the s1 as single space and reformat as \"[regsub -all {\s+} $s1 " "]\""
                                }
                        }
                }
                close $fp
        }
close $tmp_file
set tmp_file [open /home/vsduser/vsdsynth/tmp/1 r]
#puts "Reading [read $tmp_file]"
#puts "Reading /tmp/1 file as [split [read $tmp_file] \n]"
#puts "sorting /tmp/1 contents as [lsort -unique [split [read $tmp_file] \n]]"
#puts "joining /tmp/1 as [join [lsort -unique [split [read $tmp_file] \n]] \n]"
set tmp2_file [open /home/vsduser/vsdsynth/tmp/2  w]
puts -nonewline $tmp2_file "[join [lsort -unique [split [read $tmp_file] \n]] \n]"
close $tmp_file
close $tmp2_file
set tmp2_file [open /home/vsduser/vsdsynth/tmp/2 r]
puts "^^^^^^^^^OUTPUT^^^^^^^^^^^^^^^^^^"
puts "count is [read $tmp2_file] "
set count [llength [read $tmp2_file]]
puts "splitting content of tmp2_file using space and counting number of elementsas $count "
if {$count > 2} {
        set out_ports [concat [constraints get cell 0 $i]*]
        puts "bussed"
} else {
        set out_ports [constraints get cell 0 $i]
        puts "not bussed"
}
puts "outputs port name is $out_ports since count is $count"
puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $output_early_rise_delay_start $i] \[get_ports $out_ports\]"
puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $output_early_fall_delay_start $i] \[get_ports $out_ports\]"
puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $output_late_rise_delay_start $i] \[get_ports $out_ports\]"
puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $output_late_fall_delay_start $i] \[get_ports $out_ports\]"
#puts -nonewline $sdc_file "\nset_output_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_slew_start $i] \[get_ports $out_ports\]"
puts -nonewline $sdc_file "\nset_load [constraints get cell $output_load_start $i] \[get_ports $inp_ports\]"
set i [expr {$i+1}]
}
close $tmp2_file
close $sdc_file


puts "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "			DAY 4				"
puts "-----------------------------------------------------"
puts "\n INFO : Creating hierarchy check script to be used in yosys\n\n"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath} "
set filename "$DesignName.hier.ys"
set fileId [open $OutputDirectory/$filename w]
puts -nonewline $fileId $data
set netlist [glob -dir $NetlistDirectory *.v]
foreach f $netlist {
	set data $f 
	puts -nonewline $fileId "\n read_verilog $f"
}
puts -nonewline $fileId "\n hierarchy -check"
close $fileId
puts "\n close \"$OutputDirectory/$DesignName\"\n"
puts "\n**************************************"
puts "\n  Error handling in the hierarchy module\n\n "
puts "\n*****************************************"
set my_err [catch {exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log} msg]
puts "err flag is $my_err"

if {$my_err} {
	set filename "$OutputDirectory/$DesignName.hierarchy_check.log"
	puts "log file name is $filename"
	set pattern {referenced in module}
	puts "pattern is $pattern"
	set count 0
	set fid [open $filename r]
	puts "file in read mode"
	while {[gets $fid line] != -1} {
		incr count [regexp -all -- $pattern $line]
		if {[regexp -all -- $pattern $line]} {
			puts "\n Error: module [lindex $line 2] is not part of the design $DesignName. Please correct RTL in the path'$NetlistDirectory'"
			puts "\n INFO:Hierarchy check fail"
		}
	}
	close $fid
} else {
	puts "\n Hierarchy check pass"
}
puts "Please find the further info in the [file normalize $OutputDirectory/$DesignName.hierarchy_check.log] for more info"

puts "**************************************************************"
puts "			DAY 5					    "
puts "**************************************************************"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
set filename "$DesignName.ys"
set fileId [open $OutputDirectory/$filename "w"]
puts -nonewline $fileId $data
set netlist [glob -dir $NetlistDirectory *.v]
puts "syntheis DAY 5"
foreach f $netlist {
	set data $f
	puts -nonewline $fileId "\nread_verilog $f"
}
puts -nonewline $fileId "\nhierarchy -top $DesignName"
puts -nonewline $fileId "\nsynth -top $DesignName"
puts -nonewline $fileId "\nsplitnets -ports -format ___\ndfflibmap -liberty ${LateLibraryPath} \nopt"
puts -nonewline $fileId "\nabc -liberty ${LateLibraryPath}"
puts -nonewline $fileId "\nflatten"
puts -nonewline $fileId "\nclean -purge\niopadmap -outpad BUFX A:Y -bits\nopt\nclean"
puts -nonewline $fileId "\nwrite_verilog $OutputDirectory/$DesignName.synth.v"
close $fileId
puts "\nSynthesis script createdmand can be accessed from path $OutputDirectory/$DesignName.ys"

puts "\n INFO: Running synthesis..........."

#_____________________________________
# RUNNING Synthesis script using yosys
#_____________________________________
if {[catch {exec yosys -s $OutputDirectory/$DesignName.ys >& $OutputDirectory/$DesignName.synthesis.log} msg]} {
	puts "Error: synthesis failed due to errors"
	exit
} else {
	puts "Info: Synthesis finished  successfully"
}
puts "Info :Please refer to the log file : $OutputDirectory/$DesignName.synthesis.log"

#____________________________________________________
# Edit synthesis file synth.v to be used by opentimer
# ----------------------------------------------------

set fileId [open /tmp/1 "w"]
puts -nonewline $fileId [exec grep -v -w "*" $OutputDirectory/$DesignName.synth.v ]
close $fileId
set output [open $OutputDirectory/$DesignName.final.synth.v "w"]

set filename "/tmp/1"
set fid [open $filename r]
while {[gets $fid line] != -1} {
	puts -nonewline $output [string map {"//" ""} $line]
	puts -nonewline $output "\n"
}
close $fid
close $output
puts "\n Info: Please find the synthesized netlist for $DesignName design. you can proceed this synthesized netlist for PNR"
puts "\n $OutputDirectory/$DesignName.final.synth.v"
#STA USING opEN TIMER
puts "\n***************************************"
puts "\n		STA using opentimer		"
puts "\n***************************************"
puts "\nInfo: Timing Analysis Started"
puts "\nInfo: Initializing threads libraries SDC verilog netlist ........"
source /home/vsduser/vsdsynth/reopenStdout.proc
source /home/vsduser/vsdsynth/set_num_threads.proc
reopenStdout $OutputDirectory/$DesignName.conf
set conf_file [open $OutputDirectory/$DesignName.conf a]
puts $conf_file "set_multi_cpu_usage num of threads 4"

#set_multi_cpu_usage -localCpu 4
source /home/vsduser/vsdsynth/read_lib.proc
#read_lib -early /home/vsduser/vsdsynth/osu018_stdcells.lib
#read_lib -late /home/vsduser/vsdsynth/osu018_stdcells.lib
source /home/vsduser/vsdsynth/read_verilog.proc
read_verilog $OutputDirectory/$DesignName.final.synth.v
source /home/vsduser/vsdsynth/read_sdc.proc
read_sdc $OutputDirectory/$DesignName.sdc

reopenStdout /dev/tty

if {$enable_prelayout_timing == 1} {
	puts "\nInfo: enable prelayout timing is $enable_prelayout_timing. Enabling zero wire load parasitics "
	set spef_file [open $OutputDirectory/$DesignName.spef w]
	puts $spef_file "*SPEF \"IEEE 1481-1998\""
	puts $spef_file "*DESIGN \"$DesignName\" "
	puts $spef_file "*DATE \"16.17.2023\" "
	puts $spef_file "*VENDOR \"TNU\""
	puts $spef_file "*PROGRAM \"VSD \""
	puts $spef_file "*VERION \"1.1\""
	puts $spef_file "*DESIGN_FLOW \"Prelayout STA \""
	puts $spef_file "*DIVIDER \";\""
	puts $spef_file "*DELIMITER \";\""
	puts $spef_file "*BUS_DELIMITER [ ]"
	puts $spef_file "*T_UNIT 1 PS "
	puts $spef_file "*C_UNIT 1 PF "
	puts $spef_file "*R_UNIT 1 kOHM"
}
close $spef_file
#set conf_file [open $OutputDirectory/$DesignName.conf a]
puts $conf_file "set_early_celllib_fpath /home/vsduser/vsdsynth/osu018_stdcells.lib"
puts $conf_file "set_late_celllib_fpath /home/vsduser/vsdsynth/osu018_stdcells.lib"
puts $conf_file "set_timing_fpath $OutputDirectory/$DesignName.timing"
puts $conf_file  "set_spef_fpath $OutputDirectory/$DesignName.spef"
puts $conf_file "init_timer"
puts $conf_file "report_timer"
puts $conf_file "report_wns"
puts $conf_file "report_worst_paths -num_paths 10000"
close $conf_file
#/home/vsduser/OpenTimer-1.0.5/bin
set tcl_precision 3
set time_elapsed_in_us [time {exec /home/vsduser/OpenTimer-1.0.5/bin/OpenTimer < $OutputDirectory/$DesignName.conf >& $OutputDirectory/$DesignName.results} 1]
puts "time_elapsed in us is $time_elapsed_in_us"
set time_elapsed_in_sec is "[expr {[lindex $time_elapsed_in_us 0]/100000}]sec"
puts "time_elapsed in sec is $time_elapsed_in_sec"
puts "\nInfo:STA finised in $time_elapsed_in_sec sec"
puts "\nInfo: Refer to $OutputDirectory/$DesignName.results for any info"

set worst_RAT_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
puts "report file is $OutputDirectory/$DesignName.results"
set pattern {RAT}
while {[gets $report_file line] != -1} {
	if {[regexp $pattern $line]} {
		set worst_RAT_slack "[expr {[lindex $line 3]/1000}]ns"
		puts "W_RAT_sl $worst_RAT_slack"
		break
	} else {
		continue
	}
}
close $report_file
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
	incr count [regexp -all -- $pattern $line]
}
set number_setup_vio $count 
close $report_file 

#Hold violation 
set worst_neg_hold_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
puts "report file is $OutputDirectory/$DesignName.results"
set pattern {Hold}
while {[gets $report_file line] != -1} {
        if {[regexp $pattern $line]} {
                set worst_neg_hold_slack "[expr {[lindex $line 3]/1000}]ns"
               # puts "W_RAT_sl $worst_neg_hold_slack"
                break
        } else {
                continue
        }
}
close $report_file
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
        incr count [regexp -all -- $pattern $line]
}
set number_hold_vio $count
close $report_file

#Num of instance
#
#
#
set pattern {num of gates}
set report_file [open $OutputDirectory/$DesignName.results r]
#puts "report file is $OutputDirectory/$DesignName.results"

while {[gets $report_file line] != -1} {
        if {[regexp -all -- $pattern $line]} {
                set instance_count [lindex [join $line " "] 4 ]
#                puts "W_RAT_sl $worst_RAT_slack"
                break
        } else {
                continue
        }
}
close $report_file
set output_vio {expr $number_setup_vio + $number_hold_vio}
puts "DesignName is \{$OutputDirectory/$DesignName\}"
puts "time_elapsed_in_sec is \{$time_elapsed_in_sec\}"
puts "Instance count \{$instance_count\}"
puts "worst_negative setup slack is \{$worst_RAT_slack\}"
puts "Number of setup violations \{$number_setup_vio\}"
puts "Worst negative hold slack is \{$worst_neg_hold_slack\}"
puts "Number of hold violations \{$number_hold_vio\}"
puts "Worst RAT slack is \{$worst_neg_hold_slack\}"
puts "output violations \{output_vio\}"
puts "\n"
puts "*"
set formatstr {%15s%15s%15s%15s%15s%15s%15s%15s%15s%15s}
puts [format $formatstr "-----------" "--------" "--------------" "---------" "---------" "-------"  "--------" "-------" "-------"]
puts [format $formatstr "Design Name" "Run Time" "Instance count" "WNS setup" "FEP setup" "WNS Hold" "FEP Hold" "WNS RAT" "FEP RAT"]
puts [format $formatstr "-----------" "--------" "--------------" "---------" "---------" "-------"  "--------" "-------" "-------"] 
foreach design_name $DesignName runtime $time_elapsed_in_sec instance_count $instance_count wns_setup $worst_RAT_slack fep_setup $number_setup_vio wns_hold $worst_neg_hold_slack hold_vio $number_hold_vio fep_rat $worst_neg_hold_slack output_vio $output_violation {
	puts [format $formatstr $design_name $runtime $instance_count $wns_setup $fep_setup $wns_hold $hold_vio $fep_rat $output_vio]
}
puts [format $formatstr "-----------" "--------" "--------------" "---------" "---------" "-------"  "--------" "-------" "-------"]
puts "\n"





