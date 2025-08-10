1. git init
현재 디렉토리를 Git 저장소로 초기화

2. git add -A
모든 변경 사항(새 파일, 수정된 파일, 삭제된 파일)을 스테이징 영역(Staging Area)에 추가
: Git은 변경된 파일을 바로 commit하는 게 아니라, 먼저 스테이징 영역에 올려서 "다음 커밋에 포함할 파일"을 선택하는 방식을 씁니다.
: -A 옵션은 추가, 수정, 삭제 모든 변화를 한꺼번에 반영합니다.
:git add .와 비슷하지만, 삭제된 파일도 반영한다는 차이가 있습니다.

3. git commit -m "Message"
스테이징된 변경 사항을 로컬 저장소에 저장(커밋)


4. git branch -M main
현재 브랜치 이름을 main으로 강제로 변경합니다.

설명: 예전 Git은 기본 브랜치 이름이 master였지만, 현재는 main이 기본으로 권장됩니다.
-M 옵션은 브랜치 이름을 변경할 때 이미 같은 이름이 있어도 강제로 덮어씁니다.
예: master → main

5. git remote add origin https://github.com/tubiky/DutyManager.git
원격 저장소(Remote Repository)를 origin이라는 이름으로 등록


6. git push -u origin main
로컬의 main 브랜치를 원격 저장소(origin)에 업로드합니다.

설명: -u 옵션은 이 브랜치를 원격의 main 브랜치와 추적 관계(tracking)로 설정합니다.
이렇게 하면 이후에 git push나 git pull만 입력해도 브랜치 이름을 생략할 수 있습니다.

이 명령을 실행하면 처음으로 로컬 코드가 GitHub에 업로드됩니다.
