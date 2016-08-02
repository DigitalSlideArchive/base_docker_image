import os
import wget

import unittest
import docker

class TestITKOpenSlide(unittest.TestCase):
    def OpenSlideITKRead(self,image,inputImg,outputImg):

        cwd = os.getcwd()
        testEntryPoint=['python']
        testCommand=['/test/StreamProcessing.py', '/test/%s'%inputImg, '/test/%s'%outputImg, '2']
        container=self.docker_client.create_container(image,volumes=['/test'],
         host_config=self.docker_client.create_host_config(binds=[
        '%s/test:/test'%cwd
        ]),entrypoint=testEntryPoint,command=testCommand
        )
        response=self.docker_client.start(container=container.get('Id'))
        logs=self.docker_client.logs(container=container.get('Id'),stdout=True,stderr=True,stream=True)
        ret_code=self.docker_client.wait(container=container.get('Id'))      
        
        log_msg="".join(logs)
        testEntryPoint.extend(testCommand)

        error=self.getErrMsg(image, testEntryPoint) 
                   
        self.assertEqual(ret_code,0,error+log_msg)
        
    def getErrMsg(self,image,args):
        return 'Docker image %s failed to execute the following command '%image+' '.join(args)+'\n'*2
        
    def setUp(self):
        #version is set to auto so the client version is not newer than travis docker daemon
        self.docker_client=docker.Client(base_url='unix://var/run/docker.sock',version='auto')
        
    def tiff(self):
        
        
        self.OpenSlideITKRead('dsarchive/base_docker_image','27.tiff','out1.jpg')

    def test_svs(self):
        cwd=os.getcwd()
        wget.download('https://data.kitware.com/api/v1/file/57a0ed248d777f1268279da9/download',out=cwd+'/test')
        self. OpenSlideITKRead('dsarchive/base_docker_image','JP2K-33003-1.svs','out2.jpg')



