#%%
import pandas as pd
import sqlalchemy
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn import cluster
from sklearn import preprocessing

#%%
engine = sqlalchemy.create_engine('sqlite:///../../data/loyalty-system/database.db')

# %%
def import_query(path):
    with open(path) as open_file:
        return open_file.read()

query = import_query('frequencia_valor.sql')

# %%
df = pd.read_sql(query, engine)
df.head()

df = df[df['qtdePontos'] < 4000]

# %%
plt.plot(df['qtdeFrequencia'], df['qtdePontos'], 'o')
plt.grid(True)
plt.xlabel('Frequencia')
plt.ylabel('Valor')
plt.show()

# %%
minMax = preprocessing.MinMaxScaler()
x = minMax.fit_transform(df[['qtdeFrequencia', 'qtdePontos']])

df_X = pd.DataFrame(x, columns=['normFreq', 'normValor'])
df_X
#%%
kmean = cluster.KMeans(n_clusters=5, random_state=42, max_iter=1000)
kmean.fit(x)

df['cluster_calc'] = kmean.labels_

df_X['cluster'] = kmean.labels_

df.groupby(by='cluster_calc')['IdCliente'].count()

# %%
sns.scatterplot(data=df,
                x='qtdeFrequencia',
                y='qtdePontos',
                hue='cluster_calc',
                palette='Set1')
plt.hlines(y=1500, xmin=0, xmax=25, colors='gray')
plt.hlines(y=750, xmin=0, xmax=10, colors='gray')

plt.vlines(x=4, ymin=0, ymax=750, colors='gray')
plt.vlines(x=10, ymin=0, ymax=3000, colors='gray')

plt.xlabel('Frequencia')
plt.ylabel('Valor')
plt.title('Segmentação de Clientes - KMeans')
plt.legend(title='Cluster')
plt.show()
# %%
sns.scatterplot(data=df,
                x='qtdeFrequencia',
                y='qtdePontos',
                hue='cluster',
                palette='Set1')
plt.hlines(y=1500, xmin=0, xmax=25, colors='gray')
plt.hlines(y=750, xmin=0, xmax=10, colors='gray')

plt.vlines(x=4, ymin=0, ymax=750, colors='gray')
plt.vlines(x=10, ymin=0, ymax=3000, colors='gray')

plt.xlabel('Frequencia')
plt.ylabel('Valor')
plt.title('Segmentação de Clientes - KMeans')
plt.legend(title='Cluster')
plt.show()
# %%
