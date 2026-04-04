import Flutter
import Contacts
import ContactsUI
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, PHPickerViewControllerDelegate, CNContactViewControllerDelegate {
  private var pendingImportResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let mediaGalleryChannel = FlutterMethodChannel(
        name: "tempcam/media_gallery",
        binaryMessenger: controller.binaryMessenger
      )
      mediaGalleryChannel.setMethodCallHandler { [weak self] call, result in
        self?.handleMediaGalleryCall(call, result: result)
      }

      let systemChannel = FlutterMethodChannel(
        name: "tempcam/system",
        binaryMessenger: controller.binaryMessenger
      )
      systemChannel.setMethodCallHandler { [weak self] call, result in
        self?.handleSystemCall(call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleSystemCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openExternalUrl":
      guard
        let arguments = call.arguments as? [String: Any],
        let rawURL = arguments["url"] as? String,
        let url = URL(string: rawURL)
      else {
        result(FlutterError(code: "bad_args", message: "url is required.", details: nil))
        return
      }

      DispatchQueue.main.async {
        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
      }
    case "openAddContact":
      guard
        let arguments = call.arguments as? [String: Any],
        let phoneNumber = arguments["phoneNumber"] as? String,
        !phoneNumber.isEmpty
      else {
        result(
          FlutterError(code: "bad_args", message: "phoneNumber is required.", details: nil)
        )
        return
      }

      let displayName = (arguments["displayName"] as? String) ?? ""
      openAddContact(phoneNumber: phoneNumber, displayName: displayName, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleMediaGalleryCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "saveVideoToGallery":
      saveVideoToGallery(call, result: result)
    case "saveImageToGallery":
      saveImageToGallery(call, result: result)
    case "pickImportableMedia":
      presentImportPicker(result: result)
    case "consumeImportedMedia":
      consumeImportedMedia(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentImportPicker(result: @escaping FlutterResult) {
    guard pendingImportResult == nil else {
      result(
        FlutterError(
          code: "picker_active",
          message: "Another media import is already in progress.",
          details: nil
        )
      )
      return
    }

    guard #available(iOS 14, *) else {
      result(
        FlutterError(
          code: "picker_unavailable",
          message: "Media import requires iOS 14 or newer.",
          details: nil
        )
      )
      return
    }

    guard let rootViewController = window?.rootViewController else {
      result(
        FlutterError(
          code: "picker_unavailable",
          message: "Unable to present the media picker right now.",
          details: nil
        )
      )
      return
    }

    pendingImportResult = result
    DispatchQueue.main.async {
      var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
      configuration.filter = .any(of: [.images, .videos])
      configuration.selectionLimit = 0

      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      rootViewController.present(picker, animated: true)
    }
  }

  @available(iOS 14, *)
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    let resultCallback = pendingImportResult
    pendingImportResult = nil

    picker.dismiss(animated: true)

    guard let resultCallback else {
      return
    }

    if results.isEmpty {
      resultCallback([])
      return
    }

    let group = DispatchGroup()
    let lock = NSLock()
    var payloads = Array<[String: Any]?>(repeating: nil, count: results.count)
    var firstError: FlutterError?

    for (index, pickerResult) in results.enumerated() {
      group.enter()
      loadImportedItem(from: pickerResult) { payload, error in
        lock.lock()
        if let payload {
          payloads[index] = payload
        } else if firstError == nil {
          firstError = error
            ?? FlutterError(
              code: "pick_failed",
              message: "Unable to prepare the selected media for import.",
              details: nil
            )
        }
        lock.unlock()
        group.leave()
      }
    }

    group.notify(queue: .main) {
      if let firstError {
        resultCallback(firstError)
        return
      }

      let finalPayloads = payloads.compactMap { $0 }
      resultCallback(finalPayloads)
    }
  }

  @available(iOS 14, *)
  private func loadImportedItem(
    from pickerResult: PHPickerResult,
    completion: @escaping ([String: Any]?, FlutterError?) -> Void
  ) {
    let provider = pickerResult.itemProvider
    let mediaType: String
    let typeIdentifier: String

    if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
      mediaType = "video"
      typeIdentifier = UTType.movie.identifier
    } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      mediaType = "photo"
      typeIdentifier =
        provider.registeredTypeIdentifiers.first(where: { identifier in
          UTType(identifier)?.conforms(to: .image) == true
        }) ?? UTType.image.identifier
    } else {
      completion(
        nil,
        FlutterError(
          code: "pick_failed",
          message: "Unsupported media type was selected.",
          details: nil
        )
      )
      return
    }

    provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
      guard let self else {
        completion(
          nil,
          FlutterError(
            code: "pick_failed",
            message: "TempCam was unable to keep the picker alive.",
            details: nil
          )
        )
        return
      }

      if let error {
        completion(
          nil,
          FlutterError(
            code: "pick_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }

      guard let url else {
        completion(
          nil,
          FlutterError(
            code: "pick_failed",
            message: "The selected media did not provide a readable file.",
            details: nil
          )
        )
        return
      }

      do {
        let copiedURL = try self.copyPickedMediaToTemp(
          from: url,
          suggestedName: provider.suggestedName,
          mediaType: mediaType,
          typeIdentifier: typeIdentifier
        )
        completion(
          [
            "tempPath": copiedURL.path,
            "mediaType": mediaType,
            "sourceHandle": pickerResult.assetIdentifier ?? "",
          ],
          nil
        )
      } catch {
        completion(
          nil,
          FlutterError(
            code: "pick_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  @available(iOS 14, *)
  private func copyPickedMediaToTemp(
    from url: URL,
    suggestedName: String?,
    mediaType: String,
    typeIdentifier: String
  ) throws -> URL {
    let tempDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("imported_media", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

    let baseName: String
    if let suggestedName, !suggestedName.isEmpty {
      baseName = (suggestedName as NSString).deletingPathExtension
    } else {
      baseName = "tempcam_import_\(Int(Date().timeIntervalSince1970))"
    }

    let pathExtension: String
    if !url.pathExtension.isEmpty {
      pathExtension = url.pathExtension
    } else if let preferredExtension = UTType(typeIdentifier)?.preferredFilenameExtension {
      pathExtension = preferredExtension
    } else {
      pathExtension = mediaType == "video" ? "mov" : "jpg"
    }

    let fileName = "\(baseName).\(pathExtension)"
    let destinationURL = tempDirectory.appendingPathComponent(fileName, isDirectory: false)

    if FileManager.default.fileExists(atPath: destinationURL.path) {
      try FileManager.default.removeItem(at: destinationURL)
    }
    try FileManager.default.copyItem(at: url, to: destinationURL)
    return destinationURL
  }

  private func consumeImportedMedia(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(["failedOriginalDeletes": 0])
      return
    }

    let deleteOriginals = arguments["deleteOriginals"] as? Bool ?? true
    let items = arguments["items"] as? [[String: Any]] ?? []
    let tempPaths = items.compactMap { $0["tempPath"] as? String }
    let assetIdentifiers = items.compactMap { item -> String? in
      guard let sourceHandle = item["sourceHandle"] as? String, !sourceHandle.isEmpty else {
        return nil
      }
      return sourceHandle
    }

    guard deleteOriginals else {
      cleanupImportedTempFiles(tempPaths)
      result(["failedOriginalDeletes": 0])
      return
    }

    guard !assetIdentifiers.isEmpty else {
      cleanupImportedTempFiles(tempPaths)
      result(["failedOriginalDeletes": items.count])
      return
    }

    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
        guard let self else {
          DispatchQueue.main.async {
            result(["failedOriginalDeletes": assetIdentifiers.count])
          }
          return
        }

        guard status == .authorized || status == .limited else {
          self.cleanupImportedTempFiles(tempPaths)
          DispatchQueue.main.async {
            result(["failedOriginalDeletes": assetIdentifiers.count])
          }
          return
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
        var assets = [PHAsset]()
        fetchResult.enumerateObjects { asset, _, _ in
          assets.append(asset)
        }

        let unmatchedCount = max(assetIdentifiers.count - assets.count, 0)
        guard !assets.isEmpty else {
          self.cleanupImportedTempFiles(tempPaths)
          DispatchQueue.main.async {
            result(["failedOriginalDeletes": unmatchedCount])
          }
          return
        }

        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, _ in
          self.cleanupImportedTempFiles(tempPaths)
          let failedDeletes = success ? unmatchedCount : assetIdentifiers.count
          DispatchQueue.main.async {
            result(["failedOriginalDeletes": failedDeletes])
          }
        }
      }
    } else {
      cleanupImportedTempFiles(tempPaths)
      result(["failedOriginalDeletes": assetIdentifiers.count])
    }
  }

  private func saveImageToGallery(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let sourcePath = arguments["sourcePath"] as? String,
      !sourcePath.isEmpty
    else {
      result(FlutterError(code: "bad_args", message: "sourcePath is required.", details: nil))
      return
    }

    let sourceURL = URL(fileURLWithPath: sourcePath)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
      result(
        FlutterError(code: "save_failed", message: "Image file was not found.", details: nil)
      )
      return
    }

    requestPhotoLibraryWriteAccess { granted in
      guard granted else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "save_failed",
              message: "Photo Library access was not granted.",
              details: nil
            )
          )
        }
        return
      }

      var localIdentifier: String?
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: sourceURL)
        localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(localIdentifier ?? sourcePath)
          } else {
            result(
              FlutterError(
                code: "save_failed",
                message: error?.localizedDescription ?? "Unable to save the image to Photos.",
                details: nil
              )
            )
          }
        }
      }
    }
  }

  private func saveVideoToGallery(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let sourcePath = arguments["sourcePath"] as? String,
      !sourcePath.isEmpty
    else {
      result(FlutterError(code: "bad_args", message: "sourcePath is required.", details: nil))
      return
    }

    let sourceURL = URL(fileURLWithPath: sourcePath)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
      result(
        FlutterError(code: "save_failed", message: "Video file was not found.", details: nil)
      )
      return
    }

    requestPhotoLibraryWriteAccess { granted in
      guard granted else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "save_failed",
              message: "Photo Library access was not granted.",
              details: nil
            )
          )
        }
        return
      }

      var localIdentifier: String?
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: sourceURL)
        localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(localIdentifier ?? sourcePath)
          } else {
            result(
              FlutterError(
                code: "save_failed",
                message: error?.localizedDescription ?? "Unable to save the video to Photos.",
                details: nil
              )
            )
          }
        }
      }
    }
  }

  private func requestPhotoLibraryWriteAccess(_ completion: @escaping (Bool) -> Void) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        completion(status == .authorized || status == .limited)
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        completion(status == .authorized)
      }
    }
  }

  private func cleanupImportedTempFiles(_ tempPaths: [String]) {
    for path in tempPaths {
      do {
        if FileManager.default.fileExists(atPath: path) {
          try FileManager.default.removeItem(atPath: path)
        }
        let parentPath = (path as NSString).deletingLastPathComponent
        if !parentPath.isEmpty, FileManager.default.fileExists(atPath: parentPath) {
          try? FileManager.default.removeItem(atPath: parentPath)
        }
      } catch {
        continue
      }
    }
  }

  private func openAddContact(
    phoneNumber: String,
    displayName: String,
    result: @escaping FlutterResult
  ) {
    guard let rootViewController = window?.rootViewController else {
      result(
        FlutterError(
          code: "open_failed",
          message: "Unable to present the contacts view right now.",
          details: nil
        )
      )
      return
    }

    let contact = CNMutableContact()
    if !displayName.isEmpty {
      contact.givenName = displayName
    }
    contact.phoneNumbers = [
      CNLabeledValue(
        label: CNLabelPhoneNumberMobile,
        value: CNPhoneNumber(stringValue: phoneNumber)
      )
    ]

    let controller = CNContactViewController(forNewContact: contact)
    controller.contactStore = CNContactStore()
    controller.delegate = self

    let navigationController = UINavigationController(rootViewController: controller)
    DispatchQueue.main.async {
      rootViewController.present(navigationController, animated: true) {
        result(true)
      }
    }
  }

  func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
    viewController.dismiss(animated: true)
  }
}
