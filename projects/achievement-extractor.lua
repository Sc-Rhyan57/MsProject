local HttpService = game:GetService("HttpService")
local targetFolder = game:GetService("Players").LocalPlayer.PlayerGui.MainUI.LobbyFrame.Achievements.List

local achievements = {}

for _, child in pairs(targetFolder:GetChildren()) do
    local badgeId = child:GetAttribute("BadgeId")
    local category = child:GetAttribute("Category")
    local title = child:GetAttribute("Title")
    local desc = child:GetAttribute("Desc")
    local reason = child:GetAttribute("Reason")
    local secret = child:GetAttribute("Secret")
    local order = child:GetAttribute("Order")
    local image = child:GetAttribute("Image")
    
    if badgeId and category and title and desc and reason and order and image then
        local imageId = tostring(image):gsub("rbxassetid://", "")
        
        local achievement = {
            Name = child.Name,
            BadgeId = badgeId,
            Category = category,
            Title = title,
            Desc = desc,
            Reason = reason,
            Secret = secret or false,
            Order = order,
            Image = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. imageId .. "&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false"
        }
        
        table.insert(achievements, achievement)
    end
end

table.sort(achievements, function(a, b)
    return a.Order < b.Order
end)

local currentDate = os.date("%Y-%m-%d")

if not isfolder("success") then
    makefolder("success")
end

local jsonFileName = "success/" .. currentDate .. "-achievements.json"
local jsonData = HttpService:JSONEncode(achievements)
writefile(jsonFileName, jsonData)

print("(ok 1/2)")

local htmlTemplate = [[<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOORS - Achievements</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background: #0a0a0f;
            color: #e8e8e8;
            min-height: 100vh;
            padding: 20px;
            background-image: 
                linear-gradient(rgba(10, 10, 15, 0.95), rgba(10, 10, 15, 0.95)),
                repeating-linear-gradient(90deg, rgba(70, 130, 180, 0.03) 0px, transparent 1px, transparent 40px, rgba(70, 130, 180, 0.03) 41px),
                repeating-linear-gradient(0deg, rgba(70, 130, 180, 0.03) 0px, transparent 1px, transparent 40px, rgba(70, 130, 180, 0.03) 41px);
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        header {
            text-align: center;
            padding: 40px 30px;
            background: linear-gradient(135deg, rgba(25, 30, 45, 0.6), rgba(15, 20, 30, 0.6));
            border-radius: 20px;
            backdrop-filter: blur(10px);
            margin-bottom: 40px;
            border: 1px solid rgba(70, 130, 180, 0.2);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.05);
            position: relative;
            overflow: hidden;
        }

        header::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 200%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(70, 130, 180, 0.1), transparent);
            animation: shine 3s infinite;
        }

        @keyframes shine {
            0% { left: -100%; }
            100% { left: 100%; }
        }

        h1 {
            font-size: 3.5em;
            margin-bottom: 10px;
            color: #4682b4;
            text-shadow: 0 0 20px rgba(70, 130, 180, 0.5), 0 0 40px rgba(70, 130, 180, 0.3);
            font-weight: 800;
            letter-spacing: 3px;
            position: relative;
            z-index: 1;
        }

        .subtitle {
            font-size: 1.2em;
            opacity: 0.7;
            margin-top: 10px;
            position: relative;
            z-index: 1;
        }

        .controls {
            display: flex;
            gap: 15px;
            margin-bottom: 30px;
            flex-wrap: wrap;
            align-items: center;
            justify-content: center;
        }

        .search-box {
            flex: 1;
            min-width: 300px;
            max-width: 500px;
            position: relative;
        }

        .search-box input {
            width: 100%;
            padding: 14px 45px 14px 20px;
            background: rgba(25, 30, 45, 0.5);
            border: 2px solid rgba(70, 130, 180, 0.3);
            border-radius: 25px;
            color: #e8e8e8;
            font-size: 1em;
            transition: all 0.3s ease;
        }

        .search-box input:focus {
            outline: none;
            border-color: #4682b4;
            background: rgba(25, 30, 45, 0.7);
            box-shadow: 0 0 20px rgba(70, 130, 180, 0.3);
        }

        .search-box::after {
            content: '🔍';
            position: absolute;
            right: 18px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 1.2em;
            opacity: 0.5;
        }

        .stats {
            display: flex;
            justify-content: center;
            gap: 25px;
            margin-top: 25px;
            flex-wrap: wrap;
            position: relative;
            z-index: 1;
        }

        .stat-box {
            background: rgba(70, 130, 180, 0.1);
            padding: 15px 30px;
            border-radius: 15px;
            border: 1px solid rgba(70, 130, 180, 0.2);
            min-width: 120px;
            transition: all 0.3s ease;
        }

        .stat-box:hover {
            background: rgba(70, 130, 180, 0.15);
            transform: translateY(-3px);
            box-shadow: 0 5px 20px rgba(70, 130, 180, 0.2);
        }

        .stat-number {
            font-size: 2.2em;
            font-weight: 800;
            color: #4682b4;
            text-shadow: 0 0 10px rgba(70, 130, 180, 0.5);
        }

        .stat-label {
            font-size: 0.9em;
            opacity: 0.7;
            margin-top: 5px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .filters {
            display: flex;
            justify-content: center;
            gap: 12px;
            flex-wrap: wrap;
        }

        .filter-btn {
            padding: 12px 24px;
            background: rgba(25, 30, 45, 0.5);
            border: 2px solid rgba(70, 130, 180, 0.2);
            border-radius: 20px;
            color: #e8e8e8;
            cursor: pointer;
            transition: all 0.3s ease;
            font-size: 0.95em;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .filter-btn:hover {
            background: rgba(70, 130, 180, 0.2);
            border-color: #4682b4;
            transform: translateY(-2px);
        }

        .filter-btn.active {
            background: linear-gradient(135deg, #4682b4, #5a9fd4);
            border-color: #4682b4;
            box-shadow: 0 4px 15px rgba(70, 130, 180, 0.4);
        }

        .achievements-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
            gap: 25px;
            margin-bottom: 30px;
        }

        .achievement-card {
            background: linear-gradient(135deg, rgba(20, 25, 35, 0.7), rgba(15, 20, 30, 0.7));
            border-radius: 20px;
            padding: 25px;
            border: 2px solid rgba(70, 130, 180, 0.15);
            backdrop-filter: blur(10px);
            transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
        }

        .achievement-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, rgba(70, 130, 180, 0.05), rgba(100, 149, 237, 0.05));
            opacity: 0;
            transition: opacity 0.4s ease;
        }

        .achievement-card:hover {
            transform: translateY(-8px);
            border-color: rgba(70, 130, 180, 0.5);
            box-shadow: 0 15px 40px rgba(70, 130, 180, 0.2);
        }

        .achievement-card:hover::before {
            opacity: 1;
        }

        .achievement-card.secret {
            background: linear-gradient(135deg, rgba(75, 0, 130, 0.3), rgba(50, 0, 80, 0.3));
            border: 2px solid rgba(138, 43, 226, 0.4);
        }

        .achievement-card.secret::before {
            background: linear-gradient(135deg, rgba(138, 43, 226, 0.1), rgba(147, 112, 219, 0.1));
        }

        .achievement-card.secret:hover {
            border-color: rgba(147, 112, 219, 0.6);
            box-shadow: 0 15px 40px rgba(138, 43, 226, 0.3);
        }

        .achievement-header {
            display: flex;
            align-items: center;
            gap: 20px;
            margin-bottom: 20px;
            position: relative;
            z-index: 1;
        }

        .achievement-image-wrapper {
            position: relative;
            flex-shrink: 0;
        }

        .achievement-image {
            width: 85px;
            height: 85px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid rgba(70, 130, 180, 0.4);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3), 0 0 20px rgba(70, 130, 180, 0.2);
            transition: all 0.4s ease;
            background: #0a0a0f;
        }

        .achievement-card:hover .achievement-image {
            transform: scale(1.1);
            border-color: #4682b4;
            box-shadow: 0 8px 25px rgba(70, 130, 180, 0.4);
        }

        .achievement-card.secret .achievement-image {
            border-color: rgba(138, 43, 226, 0.5);
            box-shadow: 0 5px 15px rgba(138, 43, 226, 0.3);
        }

        .achievement-card.secret:hover .achievement-image {
            border-color: #8a2be2;
            box-shadow: 0 8px 25px rgba(138, 43, 226, 0.5);
        }

        .secret-icon {
            position: absolute;
            top: -5px;
            right: -5px;
            background: linear-gradient(135deg, #8a2be2, #9370db);
            width: 26px;
            height: 26px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.85em;
            border: 2px solid #0a0a0f;
            box-shadow: 0 3px 10px rgba(138, 43, 226, 0.5);
        }

        .achievement-title-section {
            flex: 1;
        }

        .achievement-title {
            font-size: 1.5em;
            font-weight: 700;
            margin-bottom: 8px;
            color: #e8e8e8;
            text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
        }

        .achievement-card.secret .achievement-title {
            color: #bb86fc;
        }

        .achievement-category {
            display: inline-block;
            padding: 5px 12px;
            background: rgba(70, 130, 180, 0.2);
            border-radius: 12px;
            font-size: 0.75em;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            border: 1px solid rgba(70, 130, 180, 0.3);
        }

        .achievement-card.secret .achievement-category {
            background: rgba(138, 43, 226, 0.2);
            border-color: rgba(138, 43, 226, 0.4);
        }

        .achievement-body {
            position: relative;
            z-index: 1;
        }

        .achievement-desc {
            font-size: 1em;
            line-height: 1.6;
            margin-bottom: 15px;
            opacity: 0.9;
            color: #d0d0d0;
        }

        .achievement-reason {
            background: rgba(0, 0, 0, 0.3);
            padding: 14px 16px;
            border-radius: 12px;
            border-left: 4px solid #4682b4;
            font-size: 0.9em;
            line-height: 1.5;
            color: #c0c0c0;
        }

        .achievement-card.secret .achievement-reason {
            border-left-color: #8a2be2;
        }

        .achievement-reason::before {
            content: '🎯 ';
            margin-right: 6px;
        }

        .achievement-footer {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 18px;
            padding-top: 15px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            position: relative;
            z-index: 1;
        }

        .badge-id {
            font-size: 0.85em;
            opacity: 0.5;
            font-weight: 500;
        }

        .secret-badge {
            background: linear-gradient(135deg, #8a2be2, #9370db);
            padding: 5px 14px;
            border-radius: 15px;
            font-size: 0.8em;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            box-shadow: 0 3px 12px rgba(138, 43, 226, 0.3);
        }

        .order-number {
            position: absolute;
            top: 18px;
            right: 18px;
            background: rgba(0, 0, 0, 0.5);
            width: 38px;
            height: 38px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 800;
            font-size: 0.95em;
            z-index: 2;
            border: 2px solid rgba(70, 130, 180, 0.3);
            color: #4682b4;
        }

        .achievement-card.secret .order-number {
            border-color: rgba(138, 43, 226, 0.4);
            color: #bb86fc;
        }

        .pagination {
            display: flex;
            justify-content: center;
            gap: 10px;
            margin-top: 30px;
            flex-wrap: wrap;
        }

        .page-btn {
            padding: 10px 18px;
            background: rgba(25, 30, 45, 0.5);
            border: 2px solid rgba(70, 130, 180, 0.2);
            border-radius: 10px;
            color: #e8e8e8;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 600;
            min-width: 45px;
        }

        .page-btn:hover {
            background: rgba(70, 130, 180, 0.2);
            border-color: #4682b4;
            transform: translateY(-2px);
        }

        .page-btn.active {
            background: linear-gradient(135deg, #4682b4, #5a9fd4);
            border-color: #4682b4;
            box-shadow: 0 4px 15px rgba(70, 130, 180, 0.4);
        }

        .page-btn:disabled {
            opacity: 0.3;
            cursor: not-allowed;
        }

        .page-btn:disabled:hover {
            transform: none;
            background: rgba(25, 30, 45, 0.5);
            border-color: rgba(70, 130, 180, 0.2);
        }

        .no-results {
            text-align: center;
            padding: 60px 20px;
            font-size: 1.3em;
            opacity: 0.5;
        }

        @media (max-width: 768px) {
            .achievements-grid {
                grid-template-columns: 1fr;
            }

            h1 {
                font-size: 2.2em;
            }

            .search-box {
                min-width: 100%;
            }

            .controls {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🚪 DOORS</h1>
            <p class="subtitle">Achievements Unlocked</p>
            <div class="stats">
                <div class="stat-box">
                    <div class="stat-number" id="totalCount">0</div>
                    <div class="stat-label">Total</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number" id="secretCount">0</div>
                    <div class="stat-label">Secret</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number" id="pageInfo">0/0</div>
                    <div class="stat-label">Page</div>
                </div>
            </div>
        </header>

        <div class="controls">
            <div class="search-box">
                <input type="text" id="searchInput" placeholder="Search achievements...">
            </div>
            <div class="filters" id="filters"></div>
        </div>

        <div class="achievements-grid" id="achievementsGrid"></div>

        <div class="pagination" id="pagination"></div>
    </div>

    <script>
        const ACHIEVEMENTS_DATA = ]] .. jsonData .. [[;

        let currentFilter = 'all';
        let currentPage = 1;
        let searchQuery = '';
        const ITEMS_PER_PAGE = 10;

        function init() {
            createFilters();
            setupSearch();
            renderAchievements();
            updateStats();
        }

        function createFilters() {
            const categories = ['all', ...new Set(ACHIEVEMENTS_DATA.map(a => a.Category))];
            const filtersContainer = document.getElementById('filters');
            
            categories.forEach(cat => {
                const btn = document.createElement('button');
                btn.className = `filter-btn ${cat === 'all' ? 'active' : ''}`;
                btn.textContent = cat === 'all' ? 'All' : cat;
                btn.onclick = () => filterBy(cat, btn);
                filtersContainer.appendChild(btn);
            });
        }

        function setupSearch() {
            const searchInput = document.getElementById('searchInput');
            searchInput.addEventListener('input', (e) => {
                searchQuery = e.target.value.toLowerCase();
                currentPage = 1;
                renderAchievements();
            });
        }

        function filterBy(category, btn) {
            currentFilter = category;
            currentPage = 1;
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            renderAchievements();
        }

        function getFilteredAchievements() {
            let filtered = currentFilter === 'all' 
                ? ACHIEVEMENTS_DATA 
                : ACHIEVEMENTS_DATA.filter(a => a.Category === currentFilter);

            if (searchQuery) {
                filtered = filtered.filter(a => 
                    a.Title.toLowerCase().includes(searchQuery) ||
                    a.Desc.toLowerCase().includes(searchQuery) ||
                    a.Reason.toLowerCase().includes(searchQuery) ||
                    a.Name.toLowerCase().includes(searchQuery)
                );
            }

            return filtered;
        }

        function extractImageUrl(thumbnailApiUrl) {
            return new Promise((resolve) => {
                fetch(thumbnailApiUrl)
                    .then(res => res.json())
                    .then(data => {
                        if (data.data && data.data[0] && data.data[0].imageUrl) {
                            resolve(data.data[0].imageUrl);
                        } else {
                            resolve('data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22100%22 height=%22100%22%3E%3Crect fill=%22%230a0a0f%22 width=%22100%22 height=%22100%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 dominant-baseline=%22middle%22 text-anchor=%22middle%22 font-size=%2250%22 fill=%22%234682b4%22%3E🏆%3C/text%3E%3C/svg%3E');
                        }
                    })
                    .catch(() => {
                        resolve('data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22100%22 height=%22100%22%3E%3Crect fill=%22%230a0a0f%22 width=%22100%22 height=%22100%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 dominant-baseline=%22middle%22 text-anchor=%22middle%22 font-size=%2250%22 fill=%22%234682b4%22%3E🏆%3C/text%3E%3C/svg%3E');
                    });
            });
        }

        async function renderAchievements() {
            const grid = document.getElementById('achievementsGrid');
            const filtered = getFilteredAchievements();
            const totalPages = Math.ceil(filtered.length / ITEMS_PER_PAGE);
            
            if (currentPage > totalPages && totalPages > 0) {
                currentPage = totalPages;
            }

            const startIndex = (currentPage - 1) * ITEMS_PER_PAGE;
            const endIndex = startIndex + ITEMS_PER_PAGE;
            const pageAchievements = filtered.slice(startIndex, endIndex);

            if (filtered.length === 0) {
                grid.innerHTML = '<div class="no-results">No achievements found</div>';
                document.getElementById('pagination').innerHTML = '';
                document.getElementById('pageInfo').textContent = '0/0';
                return;
            }

            grid.innerHTML = '';
            
            for (const achievement of pageAchievements) {
                const imageUrl = await extractImageUrl(achievement.Image);
                
                const card = document.createElement('div');
                card.className = `achievement-card ${achievement.Secret ? 'secret' : ''}`;
                card.innerHTML = `
                    <div class="order-number">#${achievement.Order}</div>
                    <div class="achievement-header">
                        <div class="achievement-image-wrapper">
                            <img src="${imageUrl}" 
                                 alt="${achievement.Title}" 
                                 class="achievement-image">
                            ${achievement.Secret ? '<div class="secret-icon">🔒</div>' : ''}
                        </div>
                        <div class="achievement-title-section">
                            <div class="achievement-title">${achievement.Title}</div>
                            <span class="achievement-category">${achievement.Category}</span>
                        </div>
                    </div>
                    <div class="achievement-body">
                        <div class="achievement-desc">${achievement.Desc}</div>
                        <div class="achievement-reason">${achievement.Reason}</div>
                    </div>
                    <div class="achievement-footer">
                        <span class="badge-id">Badge ID: ${achievement.BadgeId}</span>
                        ${achievement.Secret ? '<span class="secret-badge">🔒 SECRET</span>' : ''}
                    </div>
                `;
                grid.appendChild(card);
            }

            renderPagination(totalPages);
            document.getElementById('pageInfo').textContent = `${currentPage}/${totalPages}`;
        }

        function renderPagination(totalPages) {
            const pagination = document.getElementById('pagination');
            pagination.innerHTML = '';

            const prevBtn = document.createElement('button');
            prevBtn.className = 'page-btn';
            prevBtn.textContent = '←';
            prevBtn.disabled = currentPage === 1;
            prevBtn.onclick = () => {
                if (currentPage > 1) {
                    currentPage--;
                    renderAchievements();
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                }
            };
            pagination.appendChild(prevBtn);

            const maxVisible = 5;
            let startPage = Math.max(1, currentPage - Math.floor(maxVisible / 2));
            let endPage = Math.min(totalPages, startPage + maxVisible - 1);

            if (endPage - startPage < maxVisible - 1) {
                startPage = Math.max(1, endPage - maxVisible + 1);
            }

            for (let i = startPage; i <= endPage; i++) {
                const pageBtn = document.createElement('button');
                pageBtn.className = `page-btn ${i === currentPage ? 'active' : ''}`;
                pageBtn.textContent = i;
                pageBtn.onclick = () => {
                    currentPage = i;
                    renderAchievements();
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                };
                pagination.appendChild(pageBtn);
            }

            const nextBtn = document.createElement('button');
            nextBtn.className = 'page-btn';
            nextBtn.textContent = '→';
            nextBtn.disabled = currentPage === totalPages;
            nextBtn.onclick = () => {
                if (currentPage < totalPages) {
                    currentPage++;
                    renderAchievements();
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                }
            };
            pagination.appendChild(nextBtn);
        }

        function updateStats() {
            document.getElementById('totalCount').textContent = ACHIEVEMENTS_DATA.length;
            document.getElementById('secretCount').textContent = ACHIEVEMENTS_DATA.filter(a => a.Secret).length;
        }

        init();
    </script>
</body>
</html>]]

local htmlFileName = "success/page" .. currentDate .. ".html"
writefile(htmlFileName, htmlTemplate)

print("(ok 2/2)")
print("Arquivos salvos em: success/")
print("JSON: " .. jsonFileName)
print("HTML: " .. htmlFileName)