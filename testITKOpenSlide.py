import os
import wget

import unittest
import docker
import six


class TestITKOpenSlide(unittest.TestCase):
    def OpenSlideITKRead(self, image, inputImg, outputImg):
        cwd = os.getcwd()
        testEntryPoint = ['python']
        testCommand = ['/test/StreamProcessing.py', '/test/%s' % inputImg,
                       '/test/%s' % outputImg, '2']
        host = self.docker_client.create_host_config(
            binds=['%s/test:/test' % cwd])
        container = self.docker_client.create_container(
            image, volumes=['/test'], host_config=host,
            entrypoint=testEntryPoint, command=testCommand)
        self.docker_client.start(container=container.get('Id'))
        logs = self.docker_client.logs(container=container.get('Id'),
                                       stdout=True, stderr=True, stream=True)
        ret_code = self.docker_client.wait(container=container.get('Id'))

        log_msg = ''.join(logs)
        testEntryPoint.extend(testCommand)

        error = self.getErrMsg(image, testEntryPoint)

        self.assertEqual(ret_code, 0, error + log_msg)

    def getErrMsg(self, image, args):
        return 'Docker image %s failed to execute the following ' \
               'command ' % image + ' '.join(args) + '\n' * 2

    def setUp(self):
        # version is set to auto so the client version
        #  is not newer than travis docker daemon
        self.docker_client = docker.Client(
            base_url='unix://var/run/docker.sock', version='auto')

    def test_tiff(self):
        imgName = '27.tiff'
        imgLoc = ('https://data.kitware.com/api/v1/file/'
                  '58d526458d777f0aef5d8935/download')
        cwd = os.getcwd()
        wget.download(imgLoc, out=cwd + '/test', bar=None)
        self.OpenSlideITKRead('dsarchive/base_docker_image', imgName,
                              'out1.jpg')
        self.checkType('out1.jpg', 'ffd8ffe0')

    def test_svs(self):
        imgName = ('TCGA-CV-7242-11A-01-TS1.1838afb1-9eee-4a70-9ae3-'
                   '50e3ab45e242.svs')
        imgLoc = ('https://data.kitware.com/api/v1/file/'
                  '58d525f88d777f0aef5d8933/download')
        cwd = os.getcwd()
        wget.download(imgLoc, out=cwd + '/test', bar=None)
        self.OpenSlideITKRead('dsarchive/base_docker_image', imgName,
                              'out2.jpg')
        self.checkType('out2.jpg', 'ffd8ffe0')

    def checkType(self, imgName, header):
        imgFile = open('test/' + imgName)
        img = imgFile.read(4)
        self.assertIsInstance(
            img, six.binary_type,
            'image %s is not being read as a bytes object' % imgName)
        img = ''.join('{:02x}'.format(ord(imgByte)) for imgByte in img)
        self.assertEqual(img[:], header,
                         'First 4 bytes of the %s image is %s' % (
                         imgName, img[:]))
