                        - name: Read versions from VERSION file
                          id: read_versions
                          run: |
                            while IFS='=' read -r key value; do
                              echo "$key=$value" >> $GITHUB_ENV
                            done < VERSION
