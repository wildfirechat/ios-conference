cd WFZoom

cd WildfireSDK

cd WFChatClient.framework
lipo WFChatClient -thin arm64 -output temp
mv temp WFChatClient
cd ..

cd WFAVEngineKit.framework
lipo WFAVEngineKit -thin arm64 -output temp
mv temp WFAVEngineKit
cd ..

cd GoogleWebRTC/Frameworks/frameworks/WebRTC.framework
lipo WebRTC -thin arm64 -output temp
mv temp WebRTC
cd ../../../..

cd ..

cd Vendor/SDWebImage/SDWebImage.framework
lipo SDWebImage -thin arm64 -output temp
mv temp SDWebImage
cd ../../..

cd ..

echo "strip x86 arch done!"
