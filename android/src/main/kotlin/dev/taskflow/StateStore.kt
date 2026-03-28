package dev.taskflow

import android.content.Context
import android.content.SharedPreferences

/** Persistent key-value store using SharedPreferences. Used for chain state. */
class StateStore(private val context: Context) {
  private val prefs: SharedPreferences by lazy {
    context.getSharedPreferences("taskflow_state", Context.MODE_PRIVATE)
  }

  fun put(key: String, value: String) {
    prefs.edit().putString(key, value).apply()
  }

  fun get(key: String): String? {
    return prefs.getString(key, null)
  }

  fun delete(key: String) {
    prefs.edit().remove(key).apply()
  }

  fun getAll(): Map<String, String> {
    @Suppress("UNCHECKED_CAST")
    return prefs.all.mapValues { it.value as String }
  }
}
