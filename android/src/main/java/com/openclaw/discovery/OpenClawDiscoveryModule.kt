package com.openclaw.discovery

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import androidx.core.content.ContextCompat
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class OpenClawDiscoveryModule : Module() {
  private var nsdManager: NsdManager? = null
  private var discoveryListener: NsdManager.DiscoveryListener? = null
  private val discovered = mutableMapOf<String, NsdServiceInfo>()

  override fun definition() = ModuleDefinition {
    Name("OpenClawDiscovery")
    Events("onService", "onServiceLost", "onError")

    Function("start") { serviceType: String?, domain: String? ->
      startDiscovery(serviceType, domain)
    }

    Function("stop") {
      stopDiscovery()
    }
  }

  private fun startDiscovery(serviceType: String?, domain: String?) {
    stopDiscovery()

    val context = appContext.reactContext ?: return
    val manager = context.getSystemService(Context.NSD_SERVICE) as NsdManager
    nsdManager = manager

    val type = if (!serviceType.isNullOrBlank()) serviceType else "_openclaw-gw._tcp."

    val listener = object : NsdManager.DiscoveryListener {
      override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
        sendEvent("onError", mapOf("message" to "start_failed:$errorCode"))
        stopDiscovery()
      }

      override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
        sendEvent("onError", mapOf("message" to "stop_failed:$errorCode"))
        stopDiscovery()
      }

      override fun onDiscoveryStarted(serviceType: String) {}
      override fun onDiscoveryStopped(serviceType: String) {}

      override fun onServiceFound(serviceInfo: NsdServiceInfo) {
        val key = "${serviceInfo.serviceName}|${serviceInfo.serviceType}"
        discovered[key] = serviceInfo
        resolve(serviceInfo)
      }

      override fun onServiceLost(serviceInfo: NsdServiceInfo) {
        val key = "${serviceInfo.serviceName}|${serviceInfo.serviceType}"
        discovered.remove(key)
        sendEvent(
          "onServiceLost",
          mapOf(
            "name" to serviceInfo.serviceName,
            "type" to serviceInfo.serviceType
          )
        )
      }
    }

    discoveryListener = listener
    manager.discoverServices(type, NsdManager.PROTOCOL_DNS_SD, listener)
  }

  private fun resolve(serviceInfo: NsdServiceInfo) {
    val manager = nsdManager ?: return

    val resolveListener = object : NsdManager.ResolveListener {
      override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
        sendEvent("onError", mapOf("message" to "resolve_failed:$errorCode"))
      }

      override fun onServiceResolved(resolved: NsdServiceInfo) {
        val host = resolved.host?.hostAddress
        val port = resolved.port
        val addresses = if (host != null) listOf(host) else emptyList<String>()

        val txt = mutableMapOf<String, String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
          for ((k, v) in resolved.attributes) {
            val s = try {
              String(v, Charsets.UTF_8)
            } catch (_: Exception) {
              null
            }
            if (s != null) txt[k] = s
          }
        }

        val payload = mutableMapOf<String, Any?>(
          "name" to resolved.serviceName,
          "type" to resolved.serviceType,
          "host" to host,
          "port" to port,
          "addresses" to addresses
        )
        if (txt.isNotEmpty()) payload["txt"] = txt
        sendEvent("onService", payload)
      }
    }

    if (Build.VERSION.SDK_INT >= 34) {
      val context = appContext.reactContext
      val executor = if (context != null) ContextCompat.getMainExecutor(context) else null
      if (executor != null) {
        manager.resolveService(serviceInfo, executor, resolveListener)
      }
    } else {
      @Suppress("DEPRECATION")
      manager.resolveService(serviceInfo, resolveListener)
    }
  }

  private fun stopDiscovery() {
    val manager = nsdManager
    val listener = discoveryListener
    if (manager != null && listener != null) {
      try {
        manager.stopServiceDiscovery(listener)
      } catch (_: Exception) {
      }
    }
    discoveryListener = null
    nsdManager = null
    discovered.clear()
  }
}
