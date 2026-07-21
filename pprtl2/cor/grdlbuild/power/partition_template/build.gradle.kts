import com.intel.build.tasks.ProjectConfigTask
import com.intel.build.tasks.BuildTask

val WORKAREA  = System.getenv("WORKAREA")
var DUT       = project.findProperty("dut")
var TOPIP     = project.findProperty("topip")
var H2B_PASS  = project.findProperty("h2b_pass")
var partition = project.name

task<BuildTask>("pprtl2_elab") {
    commandLine("make elab DUT=${DUT} CONFIG=partition/${partition}.flow.cfg TOP_MODULE_NAME=${partition} TOP_IP_NAME=${TOPIP} H2B_PASS=${H2B_PASS}")
    runDir("${WORKAREA}/power/pprtl2")
    useNBResource("NB_384G_4C")
}
task<BuildTask>("pprtl2_power") {
    commandLine("make power DUT=${DUT} CONFIG=partition/${partition}.flow.cfg TOP_MODULE_NAME=${partition} TOP_IP_NAME=${TOPIP} H2B_PASS=${H2B_PASS}")
    runDir("${WORKAREA}/power/pprtl2")
    dependsOn(":power:${partition}:pprtl2_elab")
    useNBResource("NB_384G_4C")
}