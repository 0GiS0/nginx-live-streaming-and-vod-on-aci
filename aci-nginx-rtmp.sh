#Log in Azure
az login

#Variables
SUBSCRIPTION_ID = "YOUR_SUBSCRIPTION_ID"
RESOURCE_GROUP="Nginx-Demos"
AZ_STORAGE_NAME="media" #You have to create an storage account if you don't have it

#Select a subscription If you have many
az account set -s $SUBSCRIPTION_ID

az group create --name $RESOURCE_GROUP --location northeurope

#Live
cd live
docker build . -t 0gis0/nginx-rtmp-live
docker push 0gis0/nginx-rtmp-live

#Create a the Live container with nginx-rtmp
az container create \
--resource-group $RESOURCE_GROUP \
--name nginx-rtmp-live \
--image 0gis0/nginx-rtmp-live \
--dns-name-label nginx-rtmp-live --ports 1935 80 \
--cpu 2 --memory 3.5 \
--azure-file-volume-share-name recordings \
--azure-file-volume-account-name $AZ_STORAGE_NAME \
--azure-file-volume-account-key $AZ_STORAGE_KEY \
--azure-file-volume-mount-path /recordings

#ffmpeg
chmod +x ./stream.sh
./stream.sh

#Test the video
RTMP – rtmp://nginx-rtmp-live.northeurope.azurecontainer.io/live/test
HLS – http://nginx-rtmp-live.northeurope.azurecontainer.io/hls/test.m3u8
DASH – http://nginx-rtmp-live.northeurope.azurecontainer.io/dash/test.mpd


#VoD
cd vod
docker build . -t 0gis0/nginx-rtmp-vod
docker push 0gis0/nginx-rtmp-vod


#Get the Azure Storage Account Key
AZ_STORAGE_KEY=$(az storage account keys list --resource-group $AZ_STORAGE_RG --account-name $AZ_STORAGE_NAME --query "[0].value" --output tsv)

#Create a the VoD container with tiangolo/nginx-rtmp
az container create \
--resource-group $RESOURCE_GROUP \
--name nginx-rtmp-vod \
--image 0gis0/nginx-rtmp-vod \
--dns-name-label nginx-rtmp-vod --ports 80 \
--cpu 2 --memory 3.5 \
--azure-file-volume-share-name recordings \
--azure-file-volume-account-name $AZ_STORAGE_NAME \
--azure-file-volume-account-key $AZ_STORAGE_KEY \
--azure-file-volume-mount-path /opt/static/videos/
