// connect you to our gradle extensions so you'll be able to use NB, BuildTask, etc.
pluginManagement {
    repositories {
        maven("${System.getenv("GRADLE_ROOT")}/repo")
        gradlePluginPortal()
        maven("/p/hdk/rtl/proj_tools/gradle/xhdk74/7.0.2/lib")
        maven("/p/hdk/rtl/proj_tools/gradle/xhdk74/7.0.2/lib/plugins")
    }   
}
//default continue mode
startParameter.setContinueOnFailure(true)

val WORKAREA = System.getenv("WORKAREA")
val partitions = file("${WORKAREA}/power/pprtl2/prep_pprtl2_partition.list").readLines().filter { it.isNotBlank() && !it.trimStart().startsWith("#") }

partitions.forEach { partition ->
  include("power:${partition}")
  project(":power:${partition}").projectDir    = file("power/partition_template")
  project(":power:${partition}").buildFileName = "build.gradle.kts"
}