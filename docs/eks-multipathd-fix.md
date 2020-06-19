## Installing Device Mapper Multipath on Amazon EKS

If you are using EKS and need to use EBS and Pure Storage at the same time please read [this blog.](https://blog.2vcps.io/2020/06/16/hey-dont-break-ebs/)

Your multipath.conf should set a blacklist in order to prevent multipathd from managing EBS volumes. This example will make sure multipathd only manages Pure Storage volumes. Your environment and requirements may vary, this is provided as a possible solution.

```
blacklist {
    device {
        vendor "*"
    }
}
blacklist_exceptions {
    device {
        vendor "PURE"
        product "*"
    }
}
```
