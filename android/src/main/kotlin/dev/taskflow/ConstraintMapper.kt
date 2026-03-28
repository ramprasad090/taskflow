package dev.taskflow

import androidx.work.Constraints
import androidx.work.NetworkType

/** Maps TaskConstraints to Android WorkManager Constraints. */
object ConstraintMapper {
  fun fromMap(map: Map<String, Any?>?): Constraints? {
    if (map == null) return null

    val builder = Constraints.Builder()

    when (map["network"] as? String) {
      "connected" -> builder.setRequiredNetworkType(NetworkType.CONNECTED)
      "unmetered" -> builder.setRequiredNetworkType(NetworkType.UNMETERED)
    }

    if (map["batteryNotLow"] as? Boolean == true) {
      builder.setRequiresBatteryNotLow(true)
    }
    if (map["requiresCharging"] as? Boolean == true) {
      builder.setRequiresCharging(true)
    }
    if (map["deviceIdle"] as? Boolean == true) {
      builder.setRequiresDeviceIdle(true)
    }

    return builder.build()
  }
}
