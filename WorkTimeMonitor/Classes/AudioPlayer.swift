import Cocoa
import AVKit

class AudioPlayer {
    
    private var audioPlayer: AVAudioPlayer!
    
    init(audioName: String) {
        do {
            let audioAsset = NSDataAsset(name: audioName)!
            self.audioPlayer = try AVAudioPlayer(data: audioAsset.data)
            self.audioPlayer.setVolume(1, fadeDuration: 0)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func setVolume(volume: Int) {
        self.audioPlayer.setVolume(Float(volume) / Float(100.0), fadeDuration: 0)
    }
    
    func play(needToRepeat: Bool) {
        self.audioPlayer.numberOfLoops = needToRepeat ? -1 : 1
        self.audioPlayer.prepareToPlay()
        self.audioPlayer.play()
    }
    
    func pause() {
        self.audioPlayer.pause()
    }
    
    func stop() {
        self.audioPlayer.stop()
    }
    
    func isPlaying() -> Bool {
        return self.audioPlayer.isPlaying
    }
}
