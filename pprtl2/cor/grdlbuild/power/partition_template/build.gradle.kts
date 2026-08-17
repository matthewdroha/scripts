import com.intel.build.tasks.ProjectConfigTask
import com.intel.build.tasks.BuildTask

val WORKAREA  = System.getenv("WORKAREA")
var DUT       = project.findProperty("dut")
var TOPIP     = project.findProperty("topip")
var H2B_PASS  = project.findProperty("h2b_pass")
var partition = project.name
val skipVectorless = (project.findProperty("skip_vectorless") as String?)?.toBoolean() ?: false

task<BuildTask>("pprtl2_elab") {
    commandLine("make elab DUT=${DUT} CONFIG=partition/${partition}.vectorless.flow.cfg TOP_MODULE_NAME=${partition} BLOCK=${partition} TOP_IP_NAME=${TOPIP} H2B_PASS=${H2B_PASS}")
    runDir("${WORKAREA}/power/pprtl2")
    useNBResource("NB_384G_4C")
}

//-Pskip_vectorless=true will skip this task
if (!skipVectorless) {
    task<BuildTask>("pprtl2_power_vectorless") {
        commandLine("make power DUT=${DUT} CONFIG=partition/${partition}.vectorless.flow.cfg TOP_MODULE_NAME=${partition} BLOCK=${partition} TOP_IP_NAME=${TOPIP} H2B_PASS=${H2B_PASS}")
        runDir("${WORKAREA}/power/pprtl2")
        dependsOn(":power:${partition}:pprtl2_elab")
        useNBResource("NB_384G_4C")
        onlyIf("skip_vectorless not set") { !skipVectorless }
    }
}

val timebasedCfg = file("${WORKAREA}/power/pprtl2/partition/${partition}.timebased.flow.cfg")

// onlyIf() runs too late to keep these off the netbatch submission -- gate registration instead
if (timebasedCfg.exists()) {
    task<BuildTask>("pprtl2_fsdb") {
        commandLine("make fsdb DUT=${DUT} CONFIG=partition/${partition}.timebased.flow.cfg TOP_MODULE_NAME=${partition} BLOCK=${partition} TOP_IP_NAME=${TOPIP} H2B_PASS=${H2B_PASS}")
        runDir("${WORKAREA}/power/pprtl2")
        dependsOn(":power:${partition}:pprtl2_elab")
        useNBResource("NB_384G_4C")
    }

    task<BuildTask>("pprtl2_power_timebased") {
        commandLine("make power DUT=${DUT} CONFIG=partition/${partition}.timebased.flow.cfg TOP_MODULE_NAME=${partition} BLOCK=${partition} TOP_IP_NAME=${TOPIP} H2B_PASS=${H2B_PASS}")
        runDir("${WORKAREA}/power/pprtl2")
        dependsOn(":power:${partition}:pprtl2_fsdb")
        useNBResource("NB_384G_4C")
    }
}