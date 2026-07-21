plugins {
    id("com.intel.build.plugin.grdlBuildPlugins") version "1.0"
}

import com.intel.build.tasks.ProjectConfigTask
import com.intel.build.tasks.BuildTask
import com.intel.build.tasks.ConditionalTask

val WORKAREA = System.getenv("WORKAREA")
var DUT = project.findProperty("dut")
