allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// daily_flutter 0.40.0은 compileSdk 35로 고정돼 있는데, 함께 쓰는
// flutter_plugin_android_lifecycle이 36 이상을 요구한다. 플러그인 쪽만 36으로 올린다
// (minSdk·targetSdk는 그대로라 지원 기기 범위는 바뀌지 않는다).
subprojects {
    afterEvaluate {
        extensions.findByType<com.android.build.api.dsl.LibraryExtension>()?.let { android ->
            if ((android.compileSdk ?: 0) < 36) android.compileSdk = 36
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
