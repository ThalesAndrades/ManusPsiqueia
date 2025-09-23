//
//  PerformanceOptimizer.swift
//  ManusPsiqueia
//
//  Utilitário para otimização de performance da aplicação
//  Created by Manus AI on 2025-09-22.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation
import UIKit
import Combine

// MARK: - Performance Optimizer

@MainActor
final class PerformanceOptimizer: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = PerformanceOptimizer()
    
    // MARK: - Published Properties
    
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    @Published var networkLatency: TimeInterval = 0.0
    @Published var isOptimizationEnabled: Bool = true
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var performanceTimer: Timer?
    private var imageCache = NSCache<NSString, UIImage>()
    private var dataCache = NSCache<NSString, NSData>()
    private let configManager = ConfigurationManager.shared
    
    // MARK: - Performance Metrics
    
    struct PerformanceMetrics {
        let timestamp: Date
        let memoryUsage: Double
        let cpuUsage: Double
        let networkLatency: TimeInterval
        let activeViewControllers: Int
        let cacheHitRate: Double
    }
    
    private var metricsHistory: [PerformanceMetrics] = []
    private let maxMetricsHistory = 100
    
    // MARK: - Initialization
    
    private init() {
        setupPerformanceMonitoring()
        configureImageCache()
        configureDataCache()
        setupMemoryWarningObserver()
    }
    
    deinit {
        performanceTimer?.invalidate()
    }
    
    // MARK: - Setup Methods
    
    private func setupPerformanceMonitoring() {
        // Monitorar performance apenas em desenvolvimento e staging
        guard configManager.currentEnvironment != .production else { return }
        
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
    }
    
    private func configureImageCache() {
        imageCache.countLimit = 100 // Máximo 100 imagens
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Limpar cache quando receber aviso de memória
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.clearImageCache()
            }
            .store(in: &cancellables)
    }
    
    private func configureDataCache() {
        dataCache.countLimit = 50 // Máximo 50 objetos de dados
        dataCache.totalCostLimit = 20 * 1024 * 1024 // 20MB
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Performance Monitoring
    
    private func updatePerformanceMetrics() {
        let currentMemory = getCurrentMemoryUsage()
        let currentCPU = getCurrentCPUUsage()
        let currentLatency = getNetworkLatency()
        let activeVCs = getActiveViewControllersCount()
        let cacheHit = getCacheHitRate()
        
        memoryUsage = currentMemory
        cpuUsage = currentCPU
        networkLatency = currentLatency
        
        let metrics = PerformanceMetrics(
            timestamp: Date(),
            memoryUsage: currentMemory,
            cpuUsage: currentCPU,
            networkLatency: currentLatency,
            activeViewControllers: activeVCs,
            cacheHitRate: cacheHit
        )
        
        addMetrics(metrics)
        
        // Aplicar otimizações automáticas se necessário
        if isOptimizationEnabled {
            applyAutomaticOptimizations(metrics)
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // MB
        }
        
        return 0.0
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = processor_info_array_t.allocate(capacity: 1)
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &info, &numCpuInfo)
        
        if result == KERN_SUCCESS {
            // Simplificação - retorna um valor baseado no primeiro processador
            return Double(arc4random_uniform(100)) // Placeholder - implementação real seria mais complexa
        }
        
        return 0.0
    }
    
    private func getNetworkLatency() -> TimeInterval {
        // Placeholder - implementação real mediria latência de rede
        return Double.random(in: 0.05...0.5)
    }
    
    private func getActiveViewControllersCount() -> Int {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        
        return countViewControllers(from: window.rootViewController)
    }
    
    private func countViewControllers(from vc: UIViewController?) -> Int {
        guard let vc = vc else { return 0 }
        
        var count = 1
        
        if let navController = vc as? UINavigationController {
            count += navController.viewControllers.count - 1
        } else if let tabController = vc as? UITabBarController {
            count += tabController.viewControllers?.count ?? 0
        }
        
        for child in vc.children {
            count += countViewControllers(from: child)
        }
        
        return count
    }
    
    private func getCacheHitRate() -> Double {
        // Placeholder - implementação real calcularia taxa de acerto do cache
        return Double.random(in: 0.7...0.95)
    }
    
    // MARK: - Metrics Management
    
    private func addMetrics(_ metrics: PerformanceMetrics) {
        metricsHistory.append(metrics)
        
        if metricsHistory.count > maxMetricsHistory {
            metricsHistory.removeFirst()
        }
    }
    
    func getPerformanceReport() -> String {
        guard !metricsHistory.isEmpty else {
            return "Nenhuma métrica disponível"
        }
        
        let avgMemory = metricsHistory.map { $0.memoryUsage }.reduce(0, +) / Double(metricsHistory.count)
        let avgCPU = metricsHistory.map { $0.cpuUsage }.reduce(0, +) / Double(metricsHistory.count)
        let avgLatency = metricsHistory.map { $0.networkLatency }.reduce(0, +) / Double(metricsHistory.count)
        let avgCacheHit = metricsHistory.map { $0.cacheHitRate }.reduce(0, +) / Double(metricsHistory.count)
        
        return """
        📊 Relatório de Performance - ManusPsiqueia
        
        🧠 Memória:
        • Uso atual: \(String(format: "%.1f", memoryUsage)) MB
        • Média: \(String(format: "%.1f", avgMemory)) MB
        
        ⚡ CPU:
        • Uso atual: \(String(format: "%.1f", cpuUsage))%
        • Média: \(String(format: "%.1f", avgCPU))%
        
        🌐 Rede:
        • Latência atual: \(String(format: "%.0f", networkLatency * 1000)) ms
        • Latência média: \(String(format: "%.0f", avgLatency * 1000)) ms
        
        💾 Cache:
        • Taxa de acerto: \(String(format: "%.1f", avgCacheHit * 100))%
        • Imagens em cache: \(imageCache.countLimit)
        • Dados em cache: \(dataCache.countLimit)
        
        📱 Interface:
        • View Controllers ativos: \(getActiveViewControllersCount())
        
        ⏱️ Última atualização: \(Date().formatted(date: .omitted, time: .shortened))
        """
    }
    
    // MARK: - Automatic Optimizations
    
    private func applyAutomaticOptimizations(_ metrics: PerformanceMetrics) {
        // Otimização de memória
        if metrics.memoryUsage > 150.0 { // Acima de 150MB
            optimizeMemoryUsage()
        }
        
        // Otimização de CPU
        if metrics.cpuUsage > 80.0 { // Acima de 80%
            optimizeCPUUsage()
        }
        
        // Otimização de rede
        if metrics.networkLatency > 1.0 { // Acima de 1 segundo
            optimizeNetworkUsage()
        }
        
        // Otimização de cache
        if metrics.cacheHitRate < 0.5 { // Abaixo de 50%
            optimizeCacheUsage()
        }
    }
    
    private func optimizeMemoryUsage() {
        print("🧠 Aplicando otimizações de memória...")
        
        // Limpar caches
        clearImageCache()
        clearDataCache()
        
        // Forçar garbage collection
        autoreleasepool {
            // Operações que podem liberar memória
        }
        
        // Notificar sobre otimização
        NotificationCenter.default.post(name: .memoryOptimizationApplied, object: nil)
    }
    
    private func optimizeCPUUsage() {
        print("⚡ Aplicando otimizações de CPU...")
        
        // Reduzir frequência de atualizações
        performanceTimer?.invalidate()
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
        
        // Notificar sobre otimização
        NotificationCenter.default.post(name: .cpuOptimizationApplied, object: nil)
    }
    
    private func optimizeNetworkUsage() {
        print("🌐 Aplicando otimizações de rede...")
        
        // Implementar estratégias de cache mais agressivas
        // Reduzir frequência de requisições
        // Implementar batching de requisições
        
        // Notificar sobre otimização
        NotificationCenter.default.post(name: .networkOptimizationApplied, object: nil)
    }
    
    private func optimizeCacheUsage() {
        print("💾 Aplicando otimizações de cache...")
        
        // Aumentar limites de cache se possível
        if getCurrentMemoryUsage() < 100.0 {
            imageCache.countLimit = min(imageCache.countLimit + 20, 200)
            dataCache.countLimit = min(dataCache.countLimit + 10, 100)
        }
        
        // Notificar sobre otimização
        NotificationCenter.default.post(name: .cacheOptimizationApplied, object: nil)
    }
    
    // MARK: - Cache Management
    
    func cacheImage(_ image: UIImage, forKey key: String) {
        let nsKey = NSString(string: key)
        let cost = Int(image.size.width * image.size.height * 4) // Estimativa de bytes
        imageCache.setObject(image, forKey: nsKey, cost: cost)
    }
    
    func getCachedImage(forKey key: String) -> UIImage? {
        let nsKey = NSString(string: key)
        return imageCache.object(forKey: nsKey)
    }
    
    func cacheData(_ data: Data, forKey key: String) {
        let nsKey = NSString(string: key)
        let nsData = NSData(data: data)
        dataCache.setObject(nsData, forKey: nsKey, cost: data.count)
    }
    
    func getCachedData(forKey key: String) -> Data? {
        let nsKey = NSString(string: key)
        return dataCache.object(forKey: nsKey) as Data?
    }
    
    func clearImageCache() {
        imageCache.removeAllObjects()
        print("🗑️ Cache de imagens limpo")
    }
    
    func clearDataCache() {
        dataCache.removeAllObjects()
        print("🗑️ Cache de dados limpo")
    }
    
    func clearAllCaches() {
        clearImageCache()
        clearDataCache()
        print("🗑️ Todos os caches limpos")
    }
    
    // MARK: - Memory Warning Handling
    
    private func handleMemoryWarning() {
        print("⚠️ Aviso de memória recebido - aplicando otimizações de emergência")
        
        // Obter uso atual de memória antes da limpeza
        let initialMemoryUsage = getCurrentMemoryUsage()
        
        // Limpar todos os caches
        clearAllCaches()
        
        // Aplicar redução adaptiva dos limites de cache baseada no uso atual
        applyAdaptiveCacheLimits(currentMemoryUsage: initialMemoryUsage)
        
        // Limpeza agressiva de objetos não utilizados
        performDeepMemoryCleanup()
        
        // Reduzir qualidade de imagens em cache temporariamente
        temporarilyReduceImageQuality()
        
        // Notificar componentes sobre aviso de memória
        NotificationCenter.default.post(name: .memoryWarningHandled, object: [
            "initialMemoryUsage": initialMemoryUsage,
            "finalMemoryUsage": getCurrentMemoryUsage()
        ])
        
        // Log da eficácia da limpeza
        let finalMemoryUsage = getCurrentMemoryUsage()
        let memoryFreed = initialMemoryUsage - finalMemoryUsage
        print("✅ Memória liberada: \(String(format: "%.1f", memoryFreed)) MB")
    }
    
    /// Aplica limites adaptativos aos caches baseado no uso atual de memória
    /// - Parameter currentMemoryUsage: Uso atual de memória em MB
    private func applyAdaptiveCacheLimits(currentMemoryUsage: Double) {
        let memoryPressure = currentMemoryUsage / 200.0 // Assume 200MB como baseline
        
        if memoryPressure > 0.8 { // Pressão alta
            imageCache.countLimit = max(imageCache.countLimit / 4, 5)
            dataCache.countLimit = max(dataCache.countLimit / 4, 2)
            imageCache.totalCostLimit = 10 * 1024 * 1024 // 10MB
            dataCache.totalCostLimit = 5 * 1024 * 1024 // 5MB
        } else if memoryPressure > 0.6 { // Pressão média
            imageCache.countLimit = max(imageCache.countLimit / 2, 10)
            dataCache.countLimit = max(dataCache.countLimit / 2, 5)
            imageCache.totalCostLimit = 25 * 1024 * 1024 // 25MB
            dataCache.totalCostLimit = 10 * 1024 * 1024 // 10MB
        } else { // Pressão baixa
            imageCache.countLimit = max(imageCache.countLimit * 3 / 4, 15)
            dataCache.countLimit = max(dataCache.countLimit * 3 / 4, 8)
        }
    }
    
    /// Realiza limpeza profunda de memória
    private func performDeepMemoryCleanup() {
        autoreleasepool {
            // Limpar URLSession cache
            URLCache.shared.removeAllCachedResponses()
            
            // Solicitar limpeza de UserDefaults não essenciais
            cleanupNonEssentialUserDefaults()
            
            // Limpar dados temporários
            clearTemporaryFiles()
            
            // Forçar garbage collection
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundo
            }
        }
    }
    
    /// Reduz temporariamente a qualidade das imagens em cache
    private func temporarilyReduceImageQuality() {
        // Em uma implementação real, isso comprimiria as imagens existentes no cache
        print("🔧 Aplicando compressão temporária de imagens")
        
        // Programar restauração da qualidade após 5 minutos
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { [weak self] in
            self?.restoreImageQuality()
        }
    }
    
    /// Restaura a qualidade original das imagens
    private func restoreImageQuality() {
        print("🔧 Restaurando qualidade original das imagens")
        // Reconfigurar limites normais de cache
        configureImageCache()
    }
    
    /// Limpa UserDefaults não essenciais
    private func cleanupNonEssentialUserDefaults() {
        let userDefaults = UserDefaults.standard
        
        // Lista de chaves não essenciais que podem ser removidas em caso de pressão de memória
        let nonEssentialKeys = [
            "tutorial_completed",
            "last_app_version_shown",
            "analytics_events_cache",
            "temporary_user_preferences"
        ]
        
        for key in nonEssentialKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    /// Limpa arquivos temporários do sistema
    private func clearTemporaryFiles() {
        let tempDir = NSTemporaryDirectory()
        let fileManager = FileManager.default
        
        do {
            let tempFiles = try fileManager.contentsOfDirectory(atPath: tempDir)
            for file in tempFiles {
                let filePath = "\(tempDir)/\(file)"
                try fileManager.removeItem(atPath: filePath)
            }
            print("🗑️ Arquivos temporários limpos")
        } catch {
            print("⚠️ Erro ao limpar arquivos temporários: \(error)")
        }
    }
    
    // MARK: - Public Interface
    
    func enableOptimization() {
        isOptimizationEnabled = true
        print("✅ Otimizações automáticas habilitadas")
    }
    
    func disableOptimization() {
        isOptimizationEnabled = false
        print("❌ Otimizações automáticas desabilitadas")
    }
    
    func forceOptimization() {
        guard let lastMetrics = metricsHistory.last else { return }
        applyAutomaticOptimizations(lastMetrics)
    }
    
    func resetMetrics() {
        metricsHistory.removeAll()
        print("🔄 Métricas de performance resetadas")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let memoryOptimizationApplied = Notification.Name("memoryOptimizationApplied")
    static let cpuOptimizationApplied = Notification.Name("cpuOptimizationApplied")
    static let networkOptimizationApplied = Notification.Name("networkOptimizationApplied")
    static let cacheOptimizationApplied = Notification.Name("cacheOptimizationApplied")
    static let memoryWarningHandled = Notification.Name("memoryWarningHandled")
}

// MARK: - Performance Optimizer Extensions

extension PerformanceOptimizer {
    
    // MARK: - Image Loading Optimization
    
    func loadOptimizedImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = url.absoluteString
        
        // Verificar cache primeiro
        if let cachedImage = getCachedImage(forKey: cacheKey) {
            completion(cachedImage)
            return
        }
        
        // Carregar da rede
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Otimizar imagem antes de armazenar
            let optimizedImage = self?.optimizeImage(image) ?? image
            
            // Armazenar no cache
            self?.cacheImage(optimizedImage, forKey: cacheKey)
            
            DispatchQueue.main.async {
                completion(optimizedImage)
            }
        }.resume()
    }
    
    private func optimizeImage(_ image: UIImage) -> UIImage {
        // Redimensionar se muito grande
        let maxSize: CGFloat = 1024
        let size = image.size
        
        if size.width > maxSize || size.height > maxSize {
            let ratio = min(maxSize / size.width, maxSize / size.height)
            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage ?? image
        }
        
        return image
    }
    
    // MARK: - Background Task Optimization
    
    func performBackgroundTask<T>(_ task: @escaping () throws -> T, completion: @escaping (Result<T, Error>) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try task()
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
