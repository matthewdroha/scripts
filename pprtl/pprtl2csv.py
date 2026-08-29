#!/usr/intel/bin/python3

import os
import re

def main():
    #print("You are running pprtl2csv.py")
    pprtl2dict = pprtl2csv_to_dict("/nfs/site/disks/home_user/mroha/imh2_cert.csv")
    print("Block,PPRTL1_CELL_COUNT,PPRTL2_CELL_COUNT,PPRTL_SCGE,PPRTL2_SCGE,PPRTL_DCGE,PPRTL2_DCGE,PPRTL_DACGE,PPRTL2_DACGE,PPRTL_Primary_IP_annotation,PPRTL2_Primary_IP_annotation,PPRTL_Sequential_annotation,PPRTL2_Sequential_annotation,PPRTL_Untraced_sequential_percentage,PPRTL_Sequential_cells_count,PPRTL_Power_Group_Sequential_cells_count,PPRTL2_Sequential_cells_count,PPRTL2_Sequential_cells_count_MR,Elaborate_Runtime_PPRTL,Elaborate_Runtime_PPRTL2,Elaborate_Peak_Memory_PPRTL,Elaborate_Peak_Memory_PPRTL2,FSDB_Runtime_PPRTL2,FSDB_Peak_Memory_PPRTL2,Power_Runtime_PPRTL,Power_Runtime_PPRTL2,Power_Peak_Memory_PPRTL,Power_Peak_Memory_PPRTL2", sep=",")
    for block, paths in pprtl2dict.items():
        # Find the block.stat.rpt file resursively under the pprtl2dict[block]['pprtl'] directory
        # skip if block==module
        if block == "module":
            continue
        pprtl = paths['pprtl'] + "/power/avgpower"
        # print("Processing block:", block, "PPRTL path:", pprtl, "PPRTL2 path:", paths['pprtl2'])
        pprtl2 = paths['pprtl2'] + "/power/timebased"
        statsdict = {}
        statsdict[pprtl] = {}
        statsdict[pprtl2] = {}
        for root, dirs, files in os.walk(pprtl):
            for file in files:
                if re.match(rf"{block}\.stat\.rpt$", file):
                    #print(f"Found block.stat.rpt file for block {block} at {root}/{file}")
                    statfile = os.path.join(root, file)
                    # open block.stat.rpt file and create dictionary for key value pairs seperated by a colon
                    with open(statfile, "r") as statfh:
                        for line in statfh:
                            if ":" in line:
                                key, value = line.split(":", 1)
                                statsdict[pprtl][key.strip()] = value.strip()
                                #print(f"Key={key.strip()}   Value={value.strip()}")
                    #print(f"Sequential cells count={statsdict[pprtl]['Sequential cells count']}")
                    
        for root, dirs, files in os.walk(pprtl2):
            for file in files:
                if re.match(rf"{block}\.stat2\.rpt$", file):
                    #print(f"Found block.stat2.rpt file for block {block} at {root}/{file}")
                    stat2file = os.path.join(root, file)
                    # open block.stat2.rpt file and create dictionary for key value pairs seperated by a colon
                    with open(stat2file, "r") as stat2fh:
                        for line in stat2fh:
                            if ":" in line:
                                key, value = line.split(":", 1)
                                statsdict[pprtl2][key.strip()] = value.strip()
                                #print(f"Key={key.strip()}   Value={value.strip()}")
                    #print(f"Sequential cells count MR={statsdict[pprtl2]['Sequential cells count MR']}")


        # Extract the runtime and peak memory from the elaborate log file under the pprtl path
        # Extract the runtime and peak memory from the elaborate log file under the pprtl2 path
        # Runtime format is Elapsed time for this session: 79187.9 seconds (22.00 hours)  Want whats in the parentheses
        # Peak memory format for pprtl2 is Maximum memory usage for this session: 158,304,808 KB (150.97 GB)
        # Peak memory format for pprtl is Maximum memory usage for this session: 514656.78 MB

        
        pprtl_elab_log = f"{paths['pprtl']}/elab/log/elaborate.log"
        pprtl2_elab_log = f"{paths['pprtl2']}/elab/log/elaborate.log"
        # Extract the runtime and peak memory from the fsdb log file under the pprtl path
        with open(pprtl_elab_log, "r") as elabfh:
            for line in elabfh:
                mo_runtime = re.search(r"Elapsed time for this session:\s+\S+\s+seconds\s+\((.+)\)", line)
                if mo_runtime:
                    statsdict[pprtl]["Elaborate Runtime"] = mo_runtime.group(1).strip()
                mo_peakmem = re.search(r"Maximum memory usage for this session:\s+(.+)", line)
                if mo_peakmem:
                    statsdict[pprtl]["Elaborate Peak Memory"] = mo_peakmem.group(1).strip()
        
        with open(pprtl2_elab_log, "r") as elab2fh:
            for line in elab2fh:
                mo_runtime = re.search(r"Elapsed time for this session:\s+\S+\s+seconds\s+\((.+)\)", line)
                if mo_runtime:
                    statsdict[pprtl2]["Elaborate Runtime"] = mo_runtime.group(1).strip()
                mo_peakmem = re.search(r"Maximum memory usage for this session:\s+\S+\s+KB\s+\((.+)\)", line)
                if mo_peakmem:
                    statsdict[pprtl2]["Elaborate Peak Memory"] = mo_peakmem.group(1).strip()


        # Extract the runtime and peak memory from the fsdb log file under the pprtl2 path
        # For the fsdb log,  you need to look recursively for the pprtl2_path/fsdb/*/*/log/fsdb.log file
        fsdb_log = ""
        for root, dirs, files in os.walk(f"{paths['pprtl2']}/fsdb"):
            for file in files:
                if file == "fsdb.log":
                    fsdb_log = os.path.join(root, file)
                    break
            if fsdb_log:
                break
        if fsdb_log:
            with open(fsdb_log, "r") as fsdbfh:
                for line in fsdbfh:
                    mo_runtime = re.search(r"Elapsed time for this session:\s+\S+\s+seconds\s+\((.+)\)", line)
                    if mo_runtime:
                        statsdict[pprtl2]["FSDB Runtime"] = mo_runtime.group(1).strip()
                    mo_peakmem = re.search(r"Maximum memory usage for this session:\s+\S+\s+KB\s+\((.+)\)", line)
                    if mo_peakmem:
                        statsdict[pprtl2]["FSDB Peak Memory"] = mo_peakmem.group(1).strip()


        # Extract the runtime and peak memory from the power log file under the pprtl and pprtl2 paths
        # For the pprtl power log,  you need to look recursively for the pprtl_path/power/avgpower/*/*/log/power.log file
        # For the pprtl2 power log,  you need to look recursively for the pprtl2_path/power/timebased/*/*/log/power.log file
        power_log_pprtl = ""
        for root, dirs, files in os.walk(f"{paths['pprtl']}/power/avgpower"):
            for file in files:
                if file == "avgpower.log":
                    power_log_pprtl = os.path.join(root, file)
                    break
            if power_log_pprtl:
                break
        power_log_pprtl2 = ""
        for root, dirs, files in os.walk(f"{paths['pprtl2']}/power/timebased"):
            for file in files:
                if file == "timebased.log":
                    power_log_pprtl2 = os.path.join(root, file)
                    break
            if power_log_pprtl2:
                break
        if power_log_pprtl:
            with open(power_log_pprtl, "r") as powerfh:
                for line in powerfh:
                    mo_runtime = re.search(r"Elapsed time for this session:\s+(\S+)+\s", line)
                    if mo_runtime:
                        statsdict[pprtl]["Power Runtime"] = mo_runtime.group(1).strip()
                    mo_peakmem = re.search(r"Maximum memory usage for this session:\s+(.+)", line)
                    if mo_peakmem:
                        statsdict[pprtl]["Power Peak Memory"] = mo_peakmem.group(1).strip()
        if power_log_pprtl2:
            with open(power_log_pprtl2, "r") as power2fh:
                for line in power2fh:
                    mo_runtime = re.search(r"Elapsed time for this session:\s+\S+\s+seconds\s+\((.+)\)", line)
                    if mo_runtime:
                        statsdict[pprtl2]["Power Runtime"] = mo_runtime.group(1).strip()
                    mo_peakmem = re.search(r"Maximum memory usage for this session:\s+\S+\s+KB\s+\((.+)\)", line)
                    if mo_peakmem:
                        statsdict[pprtl2]["Power Peak Memory"] = mo_peakmem.group(1).strip()


        # Extract cells in sequential category from pprtl block.power_groups.rpt
        # This report file is located in the same directory as the block.stat.rpt file
        # Extract the line that looks like: sequential                           397761       Default
        power_groups_file = ""
        for root, dirs, files in os.walk(pprtl):
            for file in files:
                if re.match(rf"{block}\.power_groups\.rpt$", file):
                    power_groups_file = os.path.join(root, file)
                    break
            if power_groups_file:
                break
        if power_groups_file:
            with open(power_groups_file, "r") as pgfh:
                for line in pgfh:
                    mo_seq_cells = re.search(r"^sequential\s+(\d+)\s+", line)
                    if mo_seq_cells:
                        statsdict[pprtl]["Power Group Sequential cells count"] = mo_seq_cells.group(1).strip()
                        break
 

        #Print out a csv file that contains the following fields in this order
        #block
        #pprtl SCGE
        #pprtl2 SCGE
        #pprtl DCGE
        #pprtl2 DCGE
        #pprtl DACGE
        #pprtl2 DACGE
        #pprtl Primary I/P annotation
        #pprtl2 Primary I/P annotation
        #pprtl Sequential annotation
        #pprtl2 Sequential annotation
        #pprtl Untraced sequential percentage
        #pprtl Sequential cells count
        #pprtl Power Group Sequential cells count
        #pprtl2 Sequential cells count
        #pprtl2 Sequential cells count MR
        #pprtl Elaborate Runtime
        #pprtl2 Elaborate Runtime
        #pprtl Elaborate Peak Memory
        #pprtl2 Elaborate Peak Memory
        #pprtl2 FSDB Runtime
        #pprtl2 FSDB Peak Memory
        #pprtl Power Runtime
        #pprtl2 Power Runtime
        #pprtl Power Peak Memory
        #pprtl2 Power Peak Memory


        pprtl_scge = statsdict[pprtl].get("SCGE", "N/A")
        pprtl2_scge = statsdict[pprtl2].get("SCGE", "N/A")
        pprtl_dcge = statsdict[pprtl].get("DCGE", "N/A")
        pprtl2_dcge = statsdict[pprtl2].get("DCGE", "N/A")
        pprtl_dacge = statsdict[pprtl].get("DACGE", "N/A")
        pprtl2_dacge = statsdict[pprtl2].get("DACGE", "N/A")
        pprtl_cell_count = statsdict[pprtl].get("Total cell count", "N/A")
        pprtl2_cell_count = statsdict[pprtl2].get("Total cell count", "N/A")
        # for the annotation variables, keep only the % in the parantheses
        def extract_percentage(value):
            mo = re.search(r"\((\d+\.?\d*)%\)", value)
            if mo:
                return mo.group(1)
            else:
                return value
        pprtl_primary_ip_annotation = extract_percentage(statsdict[pprtl].get("Primary I/P annotation", "N/A"))
        pprtl2_primary_ip_annotation = extract_percentage(statsdict[pprtl2].get("Primary I/P annotation", "N/A"))
        pprtl_sequential_annotation = extract_percentage(statsdict[pprtl].get("Sequential annotation", "N/A"))
        pprtl2_sequential_annotation = extract_percentage(statsdict[pprtl2].get("Sequential annotation", "N/A"))
        pprtl_untraced_sequential_percentage = extract_percentage(statsdict[pprtl].get("Untraced sequential percentage", "N/A"))
        pprtl_sequential_cells_count = statsdict[pprtl].get("Sequential cells count", "N/A")
        pprtl_power_group_sequential_cells_count = statsdict[pprtl].get("Power Group Sequential cells count", "N/A")
        pprtl2_sequential_cells_count = statsdict[pprtl2].get("Sequential cells count", "N/A")
        pprtl2_sequential_cells_count_mr = statsdict[pprtl2].get("Sequential cells count MR", "N/A")

        # for the runtime variables,  remove the hours text
        def remove_hours_text(value):
            return value.replace(" hours", "").strip()

        # for the peak memory variables,  convert MB to GB for pprtl
        def convert_mb_to_gb(value):
            if "MB" in value:
                mb_value = re.search(r"([\d,\.]+)\s*MB", value)
                if mb_value:
                    gb_value = float(mb_value.group(1).replace(",", "")) / 1024
                    return f"{gb_value:.2f} GB"
            return value

        pprtl_elaborate_runtime = remove_hours_text(statsdict[pprtl].get("Elaborate Runtime", "N/A"))
        pprtl2_elaborate_runtime = remove_hours_text(statsdict[pprtl2].get("Elaborate Runtime", "N/A"))
        pprtl_elaborate_peak_memory = convert_mb_to_gb(statsdict[pprtl].get("Elaborate Peak Memory", "N/A"))
        pprtl2_elaborate_peak_memory = statsdict[pprtl2].get("Elaborate Peak Memory", "N/A")

        # Convert pprtl1 power runtime to hours from seconds
        def convert_seconds_to_hours(value):
            mo = re.search(r"([\d,\.]+)\s*", value)
            if mo:
                seconds = float(mo.group(1).replace(",", ""))
                hours = seconds / 3600
                return f"{hours:.2f} hours"
            return value

        pprtl_power_runtime = convert_seconds_to_hours(statsdict[pprtl].get("Power Runtime", "N/A"))
        pprtl2_power_runtime = remove_hours_text(statsdict[pprtl2].get("Power Runtime", "N/A"))
        pprtl_power_peak_memory = convert_mb_to_gb(statsdict[pprtl].get("Power Peak Memory", "N/A"))
        pprtl2_power_peak_memory = statsdict[pprtl2].get("Power Peak Memory", "N/A")

        pprtl2_fsdb_runtime = remove_hours_text(statsdict[pprtl2].get("FSDB Runtime", "N/A"))
        pprtl2_fsdb_peak_memory = statsdict[pprtl2].get("FSDB Peak Memory", "N/A")
        

    

        print(f"{block},{pprtl_cell_count},{pprtl2_cell_count},{pprtl_scge},{pprtl2_scge},{pprtl_dcge},{pprtl2_dcge},{pprtl_dacge},{pprtl2_dacge},{pprtl_primary_ip_annotation},{pprtl2_primary_ip_annotation},{pprtl_sequential_annotation},{pprtl2_sequential_annotation},{pprtl_untraced_sequential_percentage},{pprtl_sequential_cells_count},{pprtl_power_group_sequential_cells_count},{pprtl2_sequential_cells_count},{pprtl2_sequential_cells_count_mr},{pprtl_elaborate_runtime},{pprtl2_elaborate_runtime},{pprtl_elaborate_peak_memory},{pprtl2_elaborate_peak_memory},{pprtl2_fsdb_runtime},{pprtl2_fsdb_peak_memory},{pprtl_power_runtime},{pprtl2_power_runtime},{pprtl_power_peak_memory},{pprtl2_power_peak_memory}")


# Open csv file containing block, pprtl path, and pprtl2 path and create dictionary.  Ignore the first row of fields
def pprtl2csv_to_dict(csvfile):
    pprtl2dict = {}
    if os.path.isfile(csvfile):
        with open(csvfile, "r") as csvfh:
            for line in csvfh:
                if re.match(r"^\s*#", line):
                    continue
                cols = line.strip().split(",")
                if len(cols) >= 3:
                    block = cols[0].strip()
                    pprtl_path = cols[1].strip()
                    pprtl2_path = cols[2].strip()
                    pprtl2dict[block] = {
                        "pprtl": pprtl_path,
                        "pprtl2": pprtl2_path
                    }
    return pprtl2dict

if __name__ == "__main__":
    main()
