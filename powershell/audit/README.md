# Quick Start
- Create a schedule task to run *Invoke-Script.ps1* every minute to execute other scripts.
- Test-RunInterval is used to control the actual execution interval of scripts.
- https://nxlog.co/products/nxlog-community-edition/download.

# Process
1. Powershell retrieves a list of computers from AD (or a text file) and does
  - get software or process info from remote computers.
  - add additional info.
  - convert data to JSON and write to local file.
3. nxlog picks up data from local folder and send to Logstash.
4. Logstash does further processing and indexes to Elasticsearch.
