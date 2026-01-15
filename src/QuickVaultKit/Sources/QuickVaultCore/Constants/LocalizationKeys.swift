import Foundation

// MARK: - Localization Keys / 本地化键
// 集中管理所有本地化字符串键，避免硬编码字符串

public enum LocalizationKeys {
  
  // MARK: - Authentication / 认证
  
  public enum Auth {
    // Welcome / 欢迎
    public static let welcomeTitle = "auth.welcome.title"
    public static let welcomeSubtitle = "auth.welcome.subtitle"
    
    // Setup / 设置
    public static let setupTitle = "auth.setup.title"
    public static let setupSubtitle = "auth.setup.subtitle"
    public static let setupButton = "auth.setup.button"
    
    // Login / 登录
    public static let loginTitle = "auth.login.title"
    public static let loginButton = "auth.login.button"
    public static let biometricButton = "auth.biometric.button"
    
    // Password / 密码
    public static let password = "auth.password"
    public static let passwordPlaceholder = "auth.password.placeholder"
    public static let passwordRequired = "auth.password.required"
    public static let passwordHint = "auth.password.hint"
    
    // Change Password / 修改密码
    public static let changeTitle = "auth.change.title"
    public static let changeCurrent = "auth.change.current"
    public static let changeNew = "auth.change.new"
    public static let changeConfirm = "auth.change.confirm"
    public static let changeButton = "auth.change.button"
    public static let changeSuccess = "auth.change.success"
    
    // Errors / 错误
    public enum Error {
      public static let biometricUnavailable = "auth.error.biometric.unavailable"
      public static let biometricFailed = "auth.error.biometric.failed"
      public static let biometricPasswordNotStored = "auth.error.biometric.password.not.stored"
      public static let passwordIncorrect = "auth.error.password.incorrect"
      public static let passwordTooShort = "auth.error.password.too.short"
      public static let noPassword = "auth.error.no.password"
      public static let rateLimited = "auth.error.rate.limited"
      public static let keychain = "auth.error.keychain"
      public static let passwordMismatch = "auth.error.password.mismatch"
    }
  }
  
  // MARK: - Items / 项目
  
  public enum Items {
    // List / 列表
    public static let title = "items.title"
    public static let searchPlaceholder = "items.search.placeholder"
    public static let empty = "items.empty"
    public static let emptySubtitle = "items.empty.subtitle"
    public static let emptySearch = "items.empty.search"
    public static let emptySearchSubtitle = "items.empty.search.subtitle"
    
    // Types / 类型
    public enum ItemType {
      public static let text = "items.type.text"
      public static let image = "items.type.image"
      public static let file = "items.type.file"
    }
    
    // Create / 创建
    public enum Create {
      public static let title = "items.create.title"
      public static let selectType = "items.create.selecttype"
      public static let button = "items.create.button"
      public static let text = "items.create.text"
    }
    
    // Detail / 详情
    public enum Detail {
      public static let edit = "items.detail.edit"
      public static let delete = "items.detail.delete"
      public static let pin = "items.detail.pin"
      public static let unpin = "items.detail.unpin"
      public static let pinned = "items.detail.pinned"
      public static let created = "items.detail.created"
      public static let content = "items.detail.content"
      public static let images = "items.detail.images"
      public static let files = "items.detail.files"
      public static let tags = "items.detail.tags"
    }
    
    // Delete / 删除
    public enum Delete {
      public static let title = "items.delete.title"
      public static let message = "items.delete.message"
      public static let button = "items.delete.button"
    }
    
    // Info / 信息
    public enum Info {
      public static let title = "items.info.title"
      public static let basic = "items.info.basic"
    }
    
    // Content / 内容
    public enum Content {
      public static let characters = "items.content.characters"
    }
    
    // Images / 图片
    public enum Images {
      public static let section = "items.images.section"
      public static let select = "items.images.select"
      public static let count = "items.images.count"
      public static let limit = "items.images.limit"
    }
    
    // Files / 文件
    public enum Files {
      public static let section = "items.files.section"
      public static let select = "items.files.select"
      public static let count = "items.files.count"
      public static let limit = "items.files.limit"
    }
    
    // Tags / 标签
    public enum Tags {
      public static let section = "items.tags.section"
      public static let placeholder = "items.tags.placeholder"
      public static let add = "items.tags.add"
      public static let hint = "items.tags.hint"
    }
  }
  
  // MARK: - Settings / 设置
  
  public enum Settings {
    public static let title = "settings.title"
    
    // Security / 安全
    public enum Security {
      public static let title = "settings.security.title"
      public static let autolock = "settings.security.autolock"
      public static let biometric = "settings.security.biometric"
      public static let changePassword = "settings.security.changepassword"
      public static let clearData = "settings.security.cleardata"
      
      // Clear Data / 清除数据
      public enum ClearData {
        public static let title = "settings.security.cleardata.title"
        public static let message = "settings.security.cleardata.message"
        public static let confirm = "settings.security.cleardata.confirm"
        public static let success = "settings.security.cleardata.success"
      }
    }
    
    // Appearance / 外观
    public enum Appearance {
      public static let title = "settings.appearance.title"
    }
    
    // Language / 语言
    public enum Language {
      public static let title = "settings.language.title"
      public static let system = "settings.language.system"
    }
    
    // About / 关于
    public enum About {
      public static let title = "settings.about.title"
      public static let version = "settings.about.version"
    }
  }
  
  // MARK: - Watermark / 水印
  
  public enum Watermark {
    public static let title = "watermark.title"
    public static let textPlaceholder = "watermark.text.placeholder"
    
    // Sheet / 弹窗
    public enum Sheet {
      public static let title = "watermark.sheet.title"
    }
    
    // Scope / 范围
    public enum Scope {
      public static let current = "watermark.scope.current"
      public static let all = "watermark.scope.all"
    }
    
    // Spacing / 间距
    public enum Spacing {
      public static let dense = "watermark.spacing.dense"
      public static let normal = "watermark.spacing.normal"
      public static let sparse = "watermark.spacing.sparse"
    }
  }
  
  // MARK: - Export / 导出
  
  public enum Export {
    public static let addWatermark = "export.add.watermark"
    public static let watermarkPlaceholder = "export.watermark.placeholder"
    
    public enum WatermarkConfig {
      public static let title = "export.watermark.title"
      public static let hint = "export.watermark.hint"
    }
  }
  
  // MARK: - OCR
  
  public enum OCR {
    public static let processing = "ocr.processing"
    public static let success = "ocr.success"
    public static let error = "ocr.error"
  }
  
  // MARK: - Invoice / 发票
  
  public enum Invoice {
    public static let paste = "invoice.paste"
    public static let pasteHint = "invoice.paste.hint"
  }
  
  // MARK: - Promo / 推广
  
  public enum Promo {
    // PhotoPC
    public enum PhotoPC {
      public static let title = "promo.photopc.title"
      public static let description = "promo.photopc.description"
    }
    
    // FoxVault
    public enum FoxVault {
      public static let title = "promo.foxvault.title"
      public static let description = "promo.foxvault.description"
    }
  }
  
  // MARK: - Common / 通用
  
  public enum Common {
    public static let ok = "common.ok"
    public static let cancel = "common.cancel"
    public static let save = "common.save"
    public static let delete = "common.delete"
    public static let edit = "common.edit"
    public static let done = "common.done"
    public static let close = "common.close"
    public static let back = "common.back"
    public static let next = "common.next"
    public static let confirm = "common.confirm"
    public static let success = "common.success"
    public static let error = "common.error"
    public static let loading = "common.loading"
  }
}

// MARK: - String Extension for Localization / 字符串扩展用于本地化

extension String {
  /// 便捷的本地化方法
  public var localized: String {
    let languageCode = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.appLanguage) ?? "en"
    if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
       let bundle = Bundle(path: path) {
      return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
    return NSLocalizedString(self, comment: "")
  }
  
  /// 带参数的本地化方法
  public func localized(_ args: CVarArg...) -> String {
    return String(format: self.localized, arguments: args)
  }
}
