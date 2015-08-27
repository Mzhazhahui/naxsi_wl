# naxsi_wl
sample lua scripts, which make naxsi white list rules conf.
Naxsi is a wonderful and high-performance WAF, but it‘s not easy to config naxsi white-list for nginx servers, 
so I code this sample lua script to fix that.
I suppose that you already know well on naxsi its-self, such as its LearningMode, and know nginx as well. If not,
you may see https://github.com/nbs-system/naxsi and https://github.com/nginx/nginx.
1. make sure all your nginx server blocks have different "server_name", I will take the "server_name" as the config file name.
2. set naxsi config "LearningMode" to enable learning mode, error log in only learning mode is acceptable.
3. run nginx while naxsi learning mode on.
4. run naxsi_wl scripts to make naxsi white list rules for servers.

have fun~
